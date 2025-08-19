module reset_distribution_monitor (
  input wire clk,
  input wire global_reset,
  input wire [7:0] local_resets,
  output reg distribution_error
);
  reg global_reset_d;
  reg [2:0] check_state;
  
  always @(posedge clk) begin
    global_reset_d <= global_reset;
    if (global_reset && !global_reset_d)
      check_state <= 3'd0;
    else if (check_state < 3'd4)
      check_state <= check_state + 3'd1;
      
    if (check_state == 3'd3 && local_resets != 8'hFF)
      distribution_error <= 1'b1;
    else if (global_reset && !global_reset_d)
      distribution_error <= 1'b0;
  end
endmodule