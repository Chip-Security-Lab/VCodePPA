module prio_enc_dynamic_mask #(parameter W=8)(
  input clk,
  input [W-1:0] mask,
  input [W-1:0] req,
  output reg [$clog2(W)-1:0] index
);
wire [W-1:0] masked_req = req & mask;
integer i;
always @(posedge clk) begin
  index <= 0;
  for(i=0; i<W; i=i+1)
    if(masked_req[i]) index <= i[$clog2(W)-1:0];
end
endmodule