//SystemVerilog
module int_ctrl_fifo #(
    parameter DEPTH = 4,
    parameter DW = 8
) (
    input wire clk,
    input wire wr_en,
    input wire rd_en,
    input wire [DW-1:0] int_data,
    output wire full,
    output wire empty,
    output reg [DW-1:0] int_out
);
    // Memory array for FIFO storage
    reg [DW-1:0] fifo [0:DEPTH-1];
    
    // Pointers for read and write operations with extra bit for wrap detection
    reg [2:0] wr_ptr;
    reg [2:0] rd_ptr;
    
    // Registered status signals
    reg full_reg;
    reg empty_reg;
    
    // Write pointer logic
    always @(posedge clk) begin
        if (wr_en && !full_reg)
            wr_ptr <= wr_ptr + 3'b001;
    end
    
    // Read pointer logic
    always @(posedge clk) begin
        if (rd_en && !empty_reg)
            rd_ptr <= rd_ptr + 3'b001;
    end
    
    // Data write and read operations
    always @(posedge clk) begin
        if (wr_en && !full_reg)
            fifo[wr_ptr[1:0]] <= int_data;
            
        if (rd_en && !empty_reg)
            int_out <= fifo[rd_ptr[1:0]];
    end
    
    // Status calculation - optimized comparison logic
    always @(posedge clk) begin
        // Full when pointers match except for MSB
        full_reg <= (wr_ptr[2] != rd_ptr[2]) && (wr_ptr[1:0] == rd_ptr[1:0]);
        
        // Empty when pointers are exactly equal
        empty_reg <= (wr_ptr == rd_ptr);
    end
    
    // Final outputs
    assign full = full_reg;
    assign empty = empty_reg;
    
    // Initialize pointers and status registers
    initial begin
        wr_ptr = 3'b000;
        rd_ptr = 3'b000;
        full_reg = 1'b0;
        empty_reg = 1'b1;
    end
    
endmodule