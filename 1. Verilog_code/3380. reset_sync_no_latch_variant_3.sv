//SystemVerilog
module reset_sync_no_latch(
  input  wire clk,     // System clock
  input  wire rst_n,   // Active-low asynchronous reset
  output reg  synced   // Synchronized reset output
);

  // Four-stage synchronization flip-flop chain
  (* async_reg = "true" *) reg stage1;
  (* async_reg = "true" *) reg stage2;
  (* async_reg = "true" *) reg stage3;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1 <= 1'b0;
      stage2 <= 1'b0;
      stage3 <= 1'b0;
      synced <= 1'b0;
    end else begin
      stage1 <= 1'b1;
      stage2 <= stage1;
      stage3 <= stage2;
      synced <= stage3;
    end
  end

endmodule