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
reg [DW-1:0] mem [0:DEPTH-1];
reg [$clog2(DEPTH):0] wr_ptr = 0, rd_ptr = 0;

wire wr_inc = wr_en && !full;
wire rd_inc = rd_en && !empty;

always @(posedge wr_clk) begin
    if (wr_inc) mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
end

always @(posedge wr_clk) wr_ptr <= wr_ptr + wr_inc;
always @(posedge rd_clk) rd_ptr <= rd_ptr + rd_inc; // Fixed: was incorrectly using wr_ptr

assign full = (wr_ptr - rd_ptr) == DEPTH;
assign empty = (wr_ptr == rd_ptr);
assign dout = mem[rd_ptr[$clog2(DEPTH)-1:0]];
endmodule