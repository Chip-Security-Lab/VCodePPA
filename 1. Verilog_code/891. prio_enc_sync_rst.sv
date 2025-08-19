module prio_enc_sync_rst #(parameter WIDTH=8, ADDR=3)(
  input clk, rst_n,
  input [WIDTH-1:0] req_in,
  output reg [ADDR-1:0] addr_out
);
integer i;
always @(posedge clk) begin
  if (!rst_n) addr_out <= 0;
  else begin
    addr_out <= 0; // Default
    for (i=WIDTH-1; i>=0; i=i-1)
      if (req_in[i]) addr_out <= i[ADDR-1:0];
  end
end
endmodule