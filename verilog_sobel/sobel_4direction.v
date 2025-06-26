module sobel_4direction(
    input        i_clk,
    input        i_rst,
    input [71:0] i_pixel_data,
    input        i_pixel_data_valid,
    output reg [7:0] o_convolved_data,
    output reg   o_convolved_data_valid
);

    integer i; 
    
    // 4-Direction Sobel kernels
    reg signed [3:0] kernel_0   [8:0];  // 0°   - Horizontal (East-West)
    reg signed [3:0] kernel_45  [8:0];  // 45°  - Diagonal (NE-SW)
    reg signed [3:0] kernel_90  [8:0];  // 90°  - Vertical (North-South)
    reg signed [3:0] kernel_135 [8:0];  // 135° - Diagonal (NW-SE)
    
    // Multiplication results for all 8 directions
    reg signed [11:0] mult_0  [8:0];
    reg signed [11:0] mult_45 [8:0];
    reg signed [11:0] mult_90 [8:0];
    reg signed [11:0] mult_135[8:0];
    
    // Sum results for each direction
    reg signed [15:0] sum_0, sum_45, sum_90, sum_135;
    reg signed [15:0] sum_0_int, sum_45_int, sum_90_int, sum_135_int;
    
    // Pipeline registers
    reg mult_valid;
    reg sum_valid;
    reg abs_valid;
    
    // Absolute values of gradients
    reg [15:0] abs_0, abs_45, abs_90, abs_135;
    
    // Maximum gradient finding
    reg [15:0] max_01, max_23, final_max;
    
    // Initialize 4-direction Sobel kernels
    initial begin
        // 0° - Horizontal edges (East-West)
        kernel_0[0] = -1; kernel_0[1] = 0; kernel_0[2] = 1;
        kernel_0[3] = -2; kernel_0[4] = 0; kernel_0[5] = 2;
        kernel_0[6] = -1; kernel_0[7] = 0; kernel_0[8] = 1;
        
        // 45° - Diagonal edges (Northeast-Southwest)
        kernel_45[0] =  0; kernel_45[1] =  1; kernel_45[2] =  2;
        kernel_45[3] = -1; kernel_45[4] =  0; kernel_45[5] =  1;
        kernel_45[6] = -2; kernel_45[7] = -1; kernel_45[8] =  0;
        
        // 90° - Vertical edges (North-South)
        kernel_90[0] =  1; kernel_90[1] =  2; kernel_90[2] =  1;
        kernel_90[3] =  0; kernel_90[4] =  0; kernel_90[5] =  0;
        kernel_90[6] = -1; kernel_90[7] = -2; kernel_90[8] = -1;
        
        // 135° - Diagonal edges (Northwest-Southeast)
        kernel_135[0] =  2; kernel_135[1] =  1; kernel_135[2] =  0;
        kernel_135[3] =  1; kernel_135[4] =  0; kernel_135[5] = -1;
        kernel_135[6] =  0; kernel_135[7] = -1; kernel_135[8] = -2;
    end
    
    // Stage 1: Multiplication (Pipeline Stage 1)
    always @(posedge i_clk) begin
        if (i_rst) begin
            mult_valid <= 1'b0;
        end else begin
            for(i = 0; i < 9; i = i + 1) begin
                mult_0[i]   <= $signed(kernel_0[i])   * $signed({1'b0, i_pixel_data[i*8+:8]});
                mult_45[i]  <= $signed(kernel_45[i])  * $signed({1'b0, i_pixel_data[i*8+:8]});
                mult_90[i]  <= $signed(kernel_90[i])  * $signed({1'b0, i_pixel_data[i*8+:8]});
                mult_135[i] <= $signed(kernel_135[i]) * $signed({1'b0, i_pixel_data[i*8+:8]});
            end
            mult_valid <= i_pixel_data_valid;
        end
    end
    
    // Combinational sum calculation for all directions
    always @(*) begin
        sum_0_int   = 0;
        sum_45_int  = 0;
        sum_90_int  = 0;
        sum_135_int = 0;
        
        for(i = 0; i < 9; i = i + 1) begin
            sum_0_int   = sum_0_int   + mult_0[i];
            sum_45_int  = sum_45_int  + mult_45[i];
            sum_90_int  = sum_90_int  + mult_90[i];
            sum_135_int = sum_135_int + mult_135[i];
        end
    end
    
    // Stage 2: Summation (Pipeline Stage 2)
    always @(posedge i_clk) begin
        if (i_rst) begin
            sum_valid <= 1'b0;
        end else begin
            sum_0   <= sum_0_int;
            sum_45  <= sum_45_int;
            sum_90  <= sum_90_int;
            sum_135 <= sum_135_int;
            sum_valid <= mult_valid;
        end
    end
    
    // Stage 3: Absolute Value Calculation (Pipeline Stage 3)
    always @(posedge i_clk) begin
        if (i_rst) begin
            abs_valid <= 1'b0;
        end else begin
            // Calculate absolute values of all gradients
            abs_0   <= (sum_0   < 0) ? -sum_0   : sum_0;
            abs_45  <= (sum_45  < 0) ? -sum_45  : sum_45;
            abs_90  <= (sum_90  < 0) ? -sum_90  : sum_90;
            abs_135 <= (sum_135 < 0) ? -sum_135 : sum_135;
            
            abs_valid <= sum_valid;
        end
    end
    
    // Stage 4: Maximum Gradient Calculation and Thresholding
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_convolved_data_valid <= 1'b0;
        end else begin
            // Find maximum gradient among all 4 directions using tree structure
            max_01 <= (abs_0 > abs_45) ? abs_0 : abs_45;
            max_23 <= (abs_90 > abs_135) ? abs_90 : abs_135;
            final_max <= (max_01 > max_23) ? max_01 : max_23;
            
            // Apply threshold to determine edge presence
            if (final_max > 80) begin  // Adjustable threshold
                o_convolved_data <= 8'hFF;  // White (edge detected)
            end else begin
                o_convolved_data <= 8'h00;  // Black (no edge)
            end
            
            o_convolved_data_valid <= abs_valid;
        end
    end

endmodule
