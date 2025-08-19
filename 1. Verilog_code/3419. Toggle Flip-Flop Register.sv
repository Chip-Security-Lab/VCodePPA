module RD9(
  input clk, input aresetn, input toggle_en,
  output reg out_signal
);
always @(posedge clk or negedge aresetn) begin
  if (!aresetn) out_signal <= 1'b0;
  else if (toggle_en) out_signal <= ~out_signal;
end
endmodule

