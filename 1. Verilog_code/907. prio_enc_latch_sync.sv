module prio_enc_latch_sync #(parameter BITS=6)(
  input clk, latch_en, rst,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] enc_addr
);
reg [BITS-1:0] latched_data;
integer i;
always @(posedge clk) begin
  if(rst) begin
    latched_data <= 0;
    enc_addr <= 0;
  end
  else begin
    if(latch_en) latched_data <= din;
    enc_addr <= 0;
    for(i=0; i<BITS; i=i+1)
      if(latched_data[i]) enc_addr <= i[$clog2(BITS)-1:0];
  end
end
endmodule