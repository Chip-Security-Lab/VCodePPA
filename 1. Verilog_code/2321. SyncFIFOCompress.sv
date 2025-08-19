module SyncFIFOCompress #(DW=8, AW=12) (
    input clk, rst_n, wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output full, empty
);
reg [DW-1:0] mem [0:(1<<AW)-1];
reg [AW:0] wr_ptr=0, rd_ptr=0;
always @(posedge clk) begin
    if (rst_n) begin
        if (wr_en && !full) mem[wr_ptr[AW-1:0]] <= din;
        wr_ptr <= wr_en ? wr_ptr + !full : wr_ptr;
        rd_ptr <= rd_en ? rd_ptr + !empty : rd_ptr;
    end else {wr_ptr, rd_ptr} <= 0;
end
assign full = (wr_ptr - rd_ptr) == (1<<AW);
assign empty = (wr_ptr == rd_ptr);
always @(posedge clk) dout <= mem[rd_ptr[AW-1:0]];
endmodule
