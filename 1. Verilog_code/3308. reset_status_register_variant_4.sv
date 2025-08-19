//SystemVerilog
module reset_status_register(
  input clk, 
  input global_rst_n,
  input [5:0] reset_inputs_n, // Active low inputs
  input [5:0] status_clear,   // Clear individual bits
  output reg [5:0] reset_status
);
  wire [5:0] active_resets = ~reset_inputs_n;
  reg [5:0] prev_resets = 6'b000000;

  always @(posedge clk or negedge global_rst_n) begin
    prev_resets   <= (!global_rst_n) ? 6'b000000 : active_resets;
    reset_status  <= (!global_rst_n) ? 6'b000000 : ((reset_status | (active_resets & ~prev_resets)) & ~status_clear);
  end
endmodule