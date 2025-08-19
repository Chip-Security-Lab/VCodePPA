//SystemVerilog

// 顶层模块
module reset_sync_asynch (
  input  wire clk,
  input  wire arst_n,
  output wire rst_sync
);
  
  // 内部信号
  reg  stage1_reg;
  reg  stage2_reg;
  
  // 直接在顶层实现同步逻辑，无需子模块
  always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      stage1_reg <= 1'b0;
      stage2_reg <= 1'b0;
    end else begin
      stage1_reg <= 1'b1;
      stage2_reg <= stage1_reg;
    end
  end
  
  // 输出赋值
  assign rst_sync = stage2_reg;
  
endmodule