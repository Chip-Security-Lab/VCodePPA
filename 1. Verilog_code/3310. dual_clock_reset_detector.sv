module dual_clock_reset_detector(
  input clk_a, clk_b,
  input rst_src_a, rst_src_b,
  output reg reset_detected_a, reset_detected_b
);
  // Clock domain A
  reg [1:0] sync_b_to_a = 2'b00;
  reg reset_b_in_a = 1'b0;
  
  // Clock domain B
  reg [1:0] sync_a_to_b = 2'b00;
  reg reset_a_in_b = 1'b0;
  
  always @(posedge clk_a) begin
    sync_b_to_a <= {sync_b_to_a[0], rst_src_b};
    reset_b_in_a <= sync_b_to_a[1];
    reset_detected_a <= rst_src_a | reset_b_in_a;
  end
  
  always @(posedge clk_b) begin
    sync_a_to_b <= {sync_a_to_b[0], rst_src_a};
    reset_a_in_b <= sync_a_to_b[1];
    reset_detected_b <= rst_src_b | reset_a_in_b;
  end
endmodule