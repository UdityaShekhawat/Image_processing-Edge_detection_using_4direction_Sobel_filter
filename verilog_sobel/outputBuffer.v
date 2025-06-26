module outputBuffer (
    // Clock and Reset
    input  wire        s_aclk,
    input  wire        s_aresetn,
    
    // Slave (Input) AXI-Stream Interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [7:0]  s_axis_tdata,
    
    // Master (Output) AXI-Stream Interface  
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg  [7:0]  m_axis_tdata,
    
    // Status signals
    output wire        axis_prog_full,
    output wire        wr_rst_busy,    // Always 0 in this implementation
    output wire        rd_rst_busy     // Always 0 in this implementation
);

    // FIFO Parameters
    parameter FIFO_DEPTH = 512;
    parameter ADDR_WIDTH = 9;
    parameter PROG_FULL_THRESH = 480;
    
    // Internal signals
    reg [7:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [ADDR_WIDTH:0] fifo_count;
    
    // State registers
    reg fifo_empty_reg;
    reg fifo_full_reg;
    reg fifo_prog_full_reg;
    
    // Write and read enables
    wire wr_en;
    wire rd_en;
    
    // Initialize memory to prevent X states
    integer i;
    initial begin
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            fifo_mem[i] = 8'h00;
        end
    end
    
    // Reset busy signals
    assign wr_rst_busy = 1'b0;
    assign rd_rst_busy = 1'b0;
    
    // Control logic
    assign wr_en = s_axis_tvalid & s_axis_tready;
    assign rd_en = m_axis_tvalid & m_axis_tready;
    
    // Ready/Valid signals
    assign s_axis_tready = ~fifo_full_reg;
    assign axis_prog_full = fifo_prog_full_reg;
    
    // FIFO status flags calculation
    always @(posedge s_aclk) begin
        if (~s_aresetn) begin
            fifo_empty_reg <= 1'b1;
            fifo_full_reg <= 1'b0;
            fifo_prog_full_reg <= 1'b0;
        end else begin
            // Empty flag
            if (fifo_count == 0)
                fifo_empty_reg <= 1'b1;
            else if (wr_en)
                fifo_empty_reg <= 1'b0;
            
            // Full flag  
            if (fifo_count == FIFO_DEPTH)
                fifo_full_reg <= 1'b1;
            else if (rd_en)
                fifo_full_reg <= 1'b0;
                
            // Programmable full flag
            if (fifo_count >= PROG_FULL_THRESH)
                fifo_prog_full_reg <= 1'b1;
            else if (fifo_count < (PROG_FULL_THRESH - 10))
                fifo_prog_full_reg <= 1'b0;
        end
    end
    
    // FIFO count logic
    always @(posedge s_aclk) begin
        if (~s_aresetn) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en, rd_en})
                2'b00: fifo_count <= fifo_count;
                2'b01: fifo_count <= fifo_count - 1;
                2'b10: fifo_count <= fifo_count + 1;
                2'b11: fifo_count <= fifo_count;
            endcase
        end
    end
    
    // Write address pointer
    always @(posedge s_aclk) begin
        if (~s_aresetn) begin
            wr_addr <= 0;
        end else if (wr_en) begin
            if (wr_addr == FIFO_DEPTH - 1)
                wr_addr <= 0;
            else
                wr_addr <= wr_addr + 1;
        end
    end
    
    // Read address pointer
    always @(posedge s_aclk) begin
        if (~s_aresetn) begin
            rd_addr <= 0;
        end else if (rd_en) begin
            if (rd_addr == FIFO_DEPTH - 1)
                rd_addr <= 0;
            else
                rd_addr <= rd_addr + 1;
        end
    end
    
    // FIFO write operation
    always @(posedge s_aclk) begin
        if (wr_en) begin
            fifo_mem[wr_addr] <= s_axis_tdata;
        end
    end
    
    // FIFO read operation - registered output
    always @(posedge s_aclk) begin
        if (~s_aresetn) begin
            m_axis_tdata <= 8'h00;
            m_axis_tvalid <= 1'b0;
        end else begin
            if (rd_en || (~fifo_empty_reg && ~m_axis_tvalid)) begin
                m_axis_tdata <= fifo_mem[rd_addr];
            end
            
            // Valid output control
            if (~fifo_empty_reg && (~m_axis_tvalid || m_axis_tready)) begin
                m_axis_tvalid <= 1'b1;
            end else if (m_axis_tready && fifo_empty_reg) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule
