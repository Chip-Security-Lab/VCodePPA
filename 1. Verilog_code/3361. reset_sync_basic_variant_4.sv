//SystemVerilog
module reset_sync_basic(
  input  wire clk,
  input  wire async_rst_n,
  output wire sync_rst_n
);
  // Pipeline stages for reset synchronization
  reg  rst_stage1;
  reg  rst_stage2;
  reg  rst_stage3;
  
  // Multi-stage synchronization to prevent metastability
  always @(posedge clk or negedge async_rst_n) begin
    rst_stage1 <= async_rst_n ? 1'b1 : 1'b0;
    rst_stage2 <= async_rst_n ? rst_stage1 : 1'b0;
    rst_stage3 <= async_rst_n ? rst_stage2 : 1'b0;
  end
  
  // Registered output for glitch-free reset
  assign sync_rst_n = rst_stage3;
  
endmodule