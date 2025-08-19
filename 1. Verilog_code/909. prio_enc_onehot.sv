module prio_enc_onehot #(parameter W=5)(
  input [W-1:0] req_onehot,
  output reg [W-1:0] enc_out
);
integer i;
always @(*) begin
  enc_out = 0;
  for(i=0; i<W; i=i+1)
    if(req_onehot[i]) enc_out = 1 << i;
end
endmodule