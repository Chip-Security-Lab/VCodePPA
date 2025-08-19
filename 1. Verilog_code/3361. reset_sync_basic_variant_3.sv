//SystemVerilog
module reset_sync_basic(
  input  wire clk,         // System clock
  input  wire async_rst_n, // Asynchronous reset (active low)
  output reg  sync_rst_n   // Synchronized reset (active low)
);
  // Two-stage synchronizer flop chain
  (* dont_touch = "true" *)  // Preserve synchronizer chain during synthesis
  (* async_reg = "true" *)   // Mark registers as asynchronous for timing analysis
  reg stage1;

  // Reset synchronization process
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      // Asynchronous reset assertion
      {sync_rst_n, stage1} <= 2'b00;
    end else begin
      // Normal operation: shift in stable value
      {sync_rst_n, stage1} <= {stage1, 1'b1};
    end
  end
endmodule