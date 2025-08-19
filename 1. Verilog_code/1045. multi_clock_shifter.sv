module multi_clock_shifter (
  input clk_a, clk_b,
  input [7:0] data_in,
  input [2:0] shift_a, shift_b,
  output reg [7:0] data_out
);
  reg [7:0] stage_a;
  
  // First stage in clock domain A
  always @(posedge clk_a) begin
    stage_a <= data_in << shift_a;
  end
  
  // Second stage in clock domain B
  always @(posedge clk_b) begin
    data_out <= stage_a >> shift_b;
  end
endmodule
