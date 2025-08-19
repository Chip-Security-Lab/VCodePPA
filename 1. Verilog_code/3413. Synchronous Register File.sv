module RD3 #(parameter AW=2, DW=8)(
  input clk, input rst,
  input [AW-1:0] addr,
  input wr_en,
  input [DW-1:0] wdata,
  output reg [DW-1:0] rdata
);
reg [DW-1:0] mem [0:(1<<AW)-1];
integer i;
always @(posedge clk) begin
  if (rst)
    for (i=0; i<(1<<AW); i=i+1) mem[i] <= 0;
  else if (wr_en)
    mem[addr] <= wdata;
  rdata <= mem[addr];
end
endmodule
