//SystemVerilog
module sram_fifo #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input wr_clk,
    input wr_en,
    input [DW-1:0] din,
    input rd_clk,
    input rd_en,
    output [DW-1:0] dout,
    output full,
    output empty
);

// Memory array
reg [DW-1:0] mem [0:DEPTH-1];

// Pointer registers with gray encoding
reg [$clog2(DEPTH):0] wr_ptr_gray = 0;
reg [$clog2(DEPTH):0] rd_ptr_gray = 0;

// Binary pointers for memory access
wire [$clog2(DEPTH)-1:0] wr_addr = wr_ptr_gray[$clog2(DEPTH)-1:0];
wire [$clog2(DEPTH)-1:0] rd_addr = rd_ptr_gray[$clog2(DEPTH)-1:0];

// Write domain signals
wire wr_inc = wr_en && !full;
wire [$clog2(DEPTH):0] next_wr_ptr = wr_ptr_gray + wr_inc;

// Read domain signals
wire rd_inc = rd_en && !empty;
wire [$clog2(DEPTH):0] next_rd_ptr = rd_ptr_gray + rd_inc;

// Status flags
reg full_reg = 0;
reg empty_reg = 1;

// Borrow subtractor signals
wire [$clog2(DEPTH):0] diff;
wire [$clog2(DEPTH):0] borrow;
reg [$clog2(DEPTH):0] borrow_reg;

// Borrow subtractor implementation
assign {borrow, diff} = next_wr_ptr - rd_ptr_gray;

// Memory write logic
always @(posedge wr_clk) begin
    if (wr_inc) begin
        mem[wr_addr] <= din;
    end
end

// Write pointer update logic
always @(posedge wr_clk) begin
    if (wr_inc) begin
        wr_ptr_gray <= next_wr_ptr;
    end
end

// Full status logic
always @(posedge wr_clk) begin
    borrow_reg <= borrow;
    full_reg <= (diff == DEPTH) && !borrow_reg;
end

// Read pointer update logic
always @(posedge rd_clk) begin
    if (rd_inc) begin
        rd_ptr_gray <= next_rd_ptr;
    end
end

// Empty status logic
always @(posedge rd_clk) begin
    empty_reg <= (wr_ptr_gray == next_rd_ptr);
end

// Output assignments
assign full = full_reg;
assign empty = empty_reg;
assign dout = mem[rd_addr];

endmodule