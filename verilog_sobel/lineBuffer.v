module lineBuffer(
    input   i_clk,
    input   i_rst,
    input [7:0] i_data,
    input   i_data_valid,
    output [23:0] o_data,
    input i_rd_data
);
    reg [7:0] line [511:0]; // Line buffer for one image line
    reg [8:0] wrPntr;
    reg [8:0] rdPntr;
    
    // Write data to line buffer
    always @(posedge i_clk) begin
        if(i_data_valid)
            line[wrPntr] <= i_data;
    end
    
    // Write pointer control
    always @(posedge i_clk) begin
        if(i_rst)
            wrPntr <= 'd0;
        else if(i_data_valid)
            wrPntr <= wrPntr + 'd1;
    end
    
    // Output 3 consecutive pixels for 3x3 window
    assign o_data = {line[rdPntr],line[rdPntr+1],line[rdPntr+2]};
    
    // Read pointer control
    always @(posedge i_clk) begin
        if(i_rst)
            rdPntr <= 'd0;
        else if(i_rd_data)
            rdPntr <= rdPntr + 'd1;
    end
endmodule
