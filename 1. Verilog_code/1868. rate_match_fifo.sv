module rate_match_fifo #(parameter DATA_W=8, DEPTH=8) (
    input wr_clk, rd_clk, rst,
    input [DATA_W-1:0] din,
    input wr_en, rd_en,
    output full, empty,
    output [DATA_W-1:0] dout
);
reg [DATA_W-1:0] mem [0:DEPTH-1];
reg [$clog2(DEPTH):0] wr_ptr = 0, rd_ptr = 0;

always @(posedge wr_clk or posedge rst) 
    if (rst) wr_ptr <= 0;
    else if (wr_en && !full) begin
        mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
        wr_ptr <= wr_ptr + 1;
    end

always @(posedge rd_clk or posedge rst) 
    if (rst) rd_ptr <= 0;
    else if (rd_en && !empty) 
        rd_ptr <= rd_ptr + 1;

assign full = (wr_ptr - rd_ptr) >= DEPTH;
assign empty = (wr_ptr == rd_ptr);
assign dout = mem[rd_ptr[$clog2(DEPTH)-1:0]];
endmodule