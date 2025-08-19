//SystemVerilog
module reset_sync_basic(
  input  wire clk,
  input  wire async_rst_n,
  output reg  sync_rst_n
);
  // Reset synchronization chain
  (* ASYNC_REG = "TRUE" *) reg stage1;

  // Forward retimed implementation with conditional operator
  always @(posedge clk or negedge async_rst_n) begin
    stage1     <= async_rst_n ? 1'b1 : 1'b0;
    sync_rst_n <= async_rst_n ? stage1 : 1'b0;
  end
endmodule