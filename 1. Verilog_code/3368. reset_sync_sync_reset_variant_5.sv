//SystemVerilog
module reset_sync_sync_reset(
  input  wire clk,
  input  wire rst_n,
  output reg  sync_rst
);
  reg reset_stage;
  
  always @(posedge clk or negedge rst_n) begin
    reset_stage <= !rst_n ? 1'b0 : 1'b1;
    sync_rst    <= !rst_n ? 1'b0 : reset_stage;
  end
endmodule