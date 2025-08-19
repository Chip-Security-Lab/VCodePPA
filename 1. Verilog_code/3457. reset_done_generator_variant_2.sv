//SystemVerilog
module reset_done_generator (
  input wire clk,
  input wire reset_n,
  output reg reset_done
);
  
  // 中间流水线寄存器
  reg reset_n_stage1;
  reg reset_n_stage2;
  reg reset_n_stage3;
  reg reset_done_stage1;
  reg reset_done_stage2;
  
  // 流水线实现
  always @(posedge clk) begin
    if (!reset_n) begin
      // 复位所有流水线寄存器
      reset_n_stage1 <= 0;
      reset_n_stage2 <= 0;
      reset_n_stage3 <= 0;
      reset_done_stage1 <= 0;
      reset_done_stage2 <= 0;
      reset_done <= 0;
    end else begin
      // 流水线第一级 - 捕获输入复位信号
      reset_n_stage1 <= reset_n;
      
      // 流水线第二级 - 传播复位信号
      reset_n_stage2 <= reset_n_stage1;
      
      // 流水线第三级 - 继续传播复位信号
      reset_n_stage3 <= reset_n_stage2;
      
      // 流水线第四级 - 生成初步复位完成信号
      reset_done_stage1 <= reset_n_stage3;
      
      // 流水线第五级 - 传播复位完成信号
      reset_done_stage2 <= reset_done_stage1;
      
      // 流水线第六级 - 输出最终复位完成信号
      reset_done <= reset_done_stage2;
    end
  end
  
endmodule