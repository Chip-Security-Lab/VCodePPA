module int_ctrl_fifo #(DEPTH=4, DW=8) (
    input clk, wr_en, rd_en,
    input [DW-1:0] int_data,
    output full, empty,
    output reg [DW-1:0] int_out
);
reg [DW-1:0] fifo [0:DEPTH-1];
reg [1:0] wr_ptr, rd_ptr;

always @(posedge clk) begin
    if(wr_en && !full) fifo[wr_ptr] <= int_data;
    if(rd_en && !empty) int_out <= fifo[rd_ptr];
end
assign full = (wr_ptr +1) == rd_ptr;
assign empty = wr_ptr == rd_ptr;
endmodule