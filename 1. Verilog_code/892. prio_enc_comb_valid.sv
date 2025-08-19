module prio_enc_comb_valid #(parameter W=4, A=2)(
  input [W-1:0] requests,
  output reg [A-1:0] encoded_addr,
  output reg valid
);
integer i;
always @(*) begin
  encoded_addr = 0;
  valid = 0;
  for (i=0; i<W; i=i+1)
    if (requests[i]) begin
      encoded_addr = i[A-1:0];
      valid = 1;
    end
end
endmodule