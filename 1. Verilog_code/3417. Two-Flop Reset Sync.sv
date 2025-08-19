module RD7(
  input clk,
  input rst_n_in,
  output rst_n_out
);
reg r1, r2;
always @(posedge clk or negedge rst_n_in) begin
  if (!rst_n_in) begin
    r1 <= 0;
    r2 <= 0;
  end else begin
    r1 <= 1;
    r2 <= r1;
  end
end
assign rst_n_out = r2;
endmodule
