//SystemVerilog
module reset_status_register(
  input  wire        clk,
  input  wire        global_rst_n,
  input  wire [5:0]  reset_inputs_n,   // Active low inputs
  input  wire [5:0]  status_clear,     // Clear individual bits
  output reg  [5:0]  reset_status
);

  wire [5:0] active_resets;
  reg  [5:0] prev_resets;
  wire [5:0] new_reset_events;
  wire [5:0] cleared_status;
  wire [5:0] next_reset_status;

  assign active_resets      = ~reset_inputs_n;
  assign new_reset_events   = active_resets & ~prev_resets;
  assign cleared_status     = reset_status & ~status_clear;
  assign next_reset_status  = cleared_status | new_reset_events;

  always @(posedge clk or negedge global_rst_n) begin
    reset_status <= (!global_rst_n) ? 6'b000000 : next_reset_status;
    prev_resets  <= (!global_rst_n) ? 6'b000000 : active_resets;
  end

endmodule