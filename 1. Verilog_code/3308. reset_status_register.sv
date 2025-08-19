module reset_status_register(
  input clk, global_rst_n,
  input [5:0] reset_inputs_n, // Active low inputs
  input [5:0] status_clear,  // Clear individual bits
  output reg [5:0] reset_status
);
  wire [5:0] active_resets = ~reset_inputs_n;
  reg [5:0] prev_resets = 6'b000000;
  
  always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n) begin
      reset_status <= 6'b000000;
      prev_resets <= 6'b000000;
    end else begin
      prev_resets <= active_resets;
      reset_status <= (reset_status | (active_resets & ~prev_resets)) & ~status_clear;
    end
  end
endmodule