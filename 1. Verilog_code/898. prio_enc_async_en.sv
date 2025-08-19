module prio_enc_async_en #(parameter BITS=4)(
  input arst, en,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] dout
);
integer i;
always @(*) begin
  if(arst) dout = 0;
  else if(en) begin
    dout = 0;
    for(i=BITS-1; i>=0; i=i-1)
      if(din[i]) dout = i[$clog2(BITS)-1:0];
  end
  else dout = 0;
end
endmodule