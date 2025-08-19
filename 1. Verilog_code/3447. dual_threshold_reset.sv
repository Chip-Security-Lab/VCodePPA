module dual_threshold_reset (
  input wire clk,
  input wire [7:0] level,
  input wire [7:0] upper_threshold,
  input wire [7:0] lower_threshold,
  output reg reset_out
);
  always @(posedge clk) begin
    if (!reset_out && level > upper_threshold)
      reset_out <= 1'b1;
    else if (reset_out && level < lower_threshold)
      reset_out <= 1'b0;
  end
endmodule