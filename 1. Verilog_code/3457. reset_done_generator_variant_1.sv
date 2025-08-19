//SystemVerilog
module reset_done_generator (
  input  wire clk,         // 系统时钟
  input  wire reset_n,     // 异步复位信号（低电平有效）
  output wire reset_done   // 复位完成指示信号
);

  // 复位状态寄存器 - 多级复位确认
  reg reset_stage1, reset_stage2;
  
  // 多级复位检测流水线 - 提高稳定性并防止亚稳态
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_stage1 <= 1'b0;
      reset_stage2 <= 1'b0;
    end else begin
      reset_stage1 <= 1'b1;
      reset_stage2 <= reset_stage1;
    end
  end
  
  // 复位完成信号生成 - 确保稳定的复位释放
  assign reset_done = reset_stage2;

endmodule