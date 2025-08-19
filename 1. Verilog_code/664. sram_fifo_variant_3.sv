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

// Pointer registers
reg [$clog2(DEPTH):0] wr_ptr_r = 0;
reg [$clog2(DEPTH):0] rd_ptr_r = 0;

// Control signals
wire wr_inc = wr_en && !full;
wire rd_inc = rd_en && !empty;

// Write pointer logic
always @(posedge wr_clk) begin
    if (wr_inc) begin
        mem[wr_ptr_r[$clog2(DEPTH)-1:0]] <= din;
        wr_ptr_r <= wr_ptr_r + 1'b1;
    end
end

// Read pointer logic
always @(posedge rd_clk) begin
    if (rd_inc) begin
        rd_ptr_r <= rd_ptr_r + 1'b1;
    end
end

// Status flags
reg full_r = 1'b0;
reg empty_r = 1'b1;

// Status flag logic
always @(posedge wr_clk) begin
    full_r <= (wr_ptr_r - rd_ptr_r) == DEPTH;
end

always @(posedge rd_clk) begin
    empty_r <= (wr_ptr_r == rd_ptr_r);
end

// Output assignments
assign full = full_r;
assign empty = empty_r;
assign dout = mem[rd_ptr_r[$clog2(DEPTH)-1:0]];

endmodule