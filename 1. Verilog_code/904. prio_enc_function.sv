module prio_enc_function #(parameter W=16)(
  input [W-1:0] req,
  output reg [$clog2(W)-1:0] enc_addr
);
integer i;
always @(*) begin
  enc_addr = 0;
  for(i=0; i<W; i=i+1)
    if(req[i]) enc_addr = i[$clog2(W)-1:0];
end
endmodule