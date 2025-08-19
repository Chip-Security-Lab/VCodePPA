//SystemVerilog
module dual_clock_reset_detector(
  input  wire clk_a,
  input  wire clk_b,
  input  wire rst_src_a,
  input  wire rst_src_b,
  output reg  reset_detected_a,
  output reg  reset_detected_b
);

  // Synchronizers for cross-domain reset signals
  reg sync_b_to_a_ff1, sync_b_to_a_ff2;
  reg sync_a_to_b_ff1, sync_a_to_b_ff2;

  // Synchronized reset signals
  wire reset_b_synced_a;
  wire reset_a_synced_b;

  assign reset_b_synced_a = sync_b_to_a_ff2;
  assign reset_a_synced_b = sync_a_to_b_ff2;

  // Synchronize rst_src_b into clk_a domain
  always @(posedge clk_a) begin
    sync_b_to_a_ff1 <= rst_src_b;
    sync_b_to_a_ff2 <= sync_b_to_a_ff1;
    reset_detected_a <= rst_src_a | reset_b_synced_a;
  end

  // Synchronize rst_src_a into clk_b domain
  always @(posedge clk_b) begin
    sync_a_to_b_ff1 <= rst_src_a;
    sync_a_to_b_ff2 <= sync_a_to_b_ff1;
    reset_detected_b <= rst_src_b | reset_a_synced_b;
  end

endmodule