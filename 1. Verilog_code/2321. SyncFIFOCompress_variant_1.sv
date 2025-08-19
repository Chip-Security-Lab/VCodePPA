//SystemVerilog
module SyncFIFOCompress #(
    parameter DW = 8,  // Data width
    parameter AW = 12  // Address width
) (
    input                  clk,    // Clock signal
    input                  rst_n,  // Active low reset
    input                  wr_en,  // Write enable
    input                  rd_en,  // Read enable
    input      [DW-1:0]    din,    // Data input
    output reg [DW-1:0]    dout,   // Data output
    output                 full,   // FIFO full flag
    output                 empty   // FIFO empty flag
);

    // Memory declaration
    reg [DW-1:0] fifo_mem [0:(1<<AW)-1];
    
    // Pointer registers
    reg [AW:0] wr_ptr_q = 0;
    reg [AW:0] rd_ptr_q = 0;
    
    // Pipeline registers for status flags
    reg full_q = 0;
    reg empty_q = 1;
    
    // Status signals
    wire wr_allowed;
    wire rd_allowed;
    wire [AW:0] next_wr_ptr;
    wire [AW:0] next_rd_ptr;
    wire [AW-1:0] wr_addr;
    wire [AW-1:0] rd_addr;
    
    // Extract addresses from pointers
    assign wr_addr = wr_ptr_q[AW-1:0];
    assign rd_addr = rd_ptr_q[AW-1:0];
    
    // Permission signals
    assign wr_allowed = wr_en && !full_q;
    assign rd_allowed = rd_en && !empty_q;
    
    // Next pointer values
    assign next_wr_ptr = wr_allowed ? wr_ptr_q + 1'b1 : wr_ptr_q;
    assign next_rd_ptr = rd_allowed ? rd_ptr_q + 1'b1 : rd_ptr_q;
    
    // Status flags calculation using conditional sum subtraction
    wire [AW:0] fifo_count;
    
    // Conditional Sum Subtraction for wr_ptr_q - rd_ptr_q
    wire [AW:0] rd_ptr_inv;
    wire [AW:0] partial_sum0, partial_sum1;
    wire carry_in;
    
    // Invert rd_ptr_q (ones' complement)
    assign rd_ptr_inv = ~rd_ptr_q;
    // Add 1 to get two's complement
    assign carry_in = 1'b1;
    
    // Generate two possible sums:
    // partial_sum0: assuming carry-in = 0
    // partial_sum1: assuming carry-in = 1
    assign partial_sum0 = wr_ptr_q + rd_ptr_inv;
    assign partial_sum1 = wr_ptr_q + rd_ptr_inv + 1'b1;
    
    // Select the correct sum based on carry_in
    assign fifo_count = carry_in ? partial_sum1 : partial_sum0;
    
    wire will_be_full;
    wire will_be_empty;
    
    assign will_be_full = (next_wr_ptr[AW-1:0] == next_rd_ptr[AW-1:0]) && 
                           (next_wr_ptr[AW] != next_rd_ptr[AW]);
    assign will_be_empty = (next_wr_ptr == next_rd_ptr);
    
    // Output status flags
    assign full = full_q;
    assign empty = empty_q;
    
    // Write operation to memory
    always @(posedge clk) begin
        if (wr_allowed) begin
            fifo_mem[wr_addr] <= din;
        end
    end
    
    // Read operation from memory and update dout
    reg [DW-1:0] pre_dout;
    
    always @(posedge clk) begin
        if (rd_allowed) begin
            pre_dout <= fifo_mem[rd_addr];
        end
    end
    
    // Register output data
    always @(posedge clk) begin
        dout <= pre_dout;
    end
    
    // Pointer and status update
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_q <= 0;
            rd_ptr_q <= 0;
            full_q <= 0;
            empty_q <= 1;
        end else begin
            wr_ptr_q <= next_wr_ptr;
            rd_ptr_q <= next_rd_ptr;
            full_q <= will_be_full;
            empty_q <= will_be_empty;
        end
    end

endmodule