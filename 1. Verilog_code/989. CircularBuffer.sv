module CircularBuffer #(parameter DEPTH=8, ADDR_WIDTH=3) (
    input clk, wr_en, rd_en,
    input data_in,
    output reg data_out
);
reg [DEPTH-1:0] mem;
reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
always @(posedge clk) begin
    if (wr_en) mem[wr_ptr] <= data_in;
    if (rd_en) data_out <= mem[rd_ptr];
    wr_ptr <= wr_ptr + wr_en;
    rd_ptr <= rd_ptr + rd_en;
end
endmodule