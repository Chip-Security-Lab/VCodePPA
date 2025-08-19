//SystemVerilog
module reset_glitch_detector (
  input  wire clk,          // 时钟输入信号
  input  wire reset_n,      // 复位信号输入（低电平有效）
  output wire glitch_detected, // 毛刺检测输出
  input  wire enable,       // 流水线使能信号
  output wire valid_out     // 输出有效信号
);
  
  // 第一级流水线寄存器
  reg reset_stage1;
  reg valid_stage1;
  
  // 第二级流水线寄存器
  reg reset_stage2;
  reg valid_stage2;
  
  // 第三级流水线寄存器
  reg reset_stage3;
  reg valid_stage3;
  
  // 流水线数据处理
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      // 复位所有流水线寄存器
      reset_stage1 <= 1'b1;
      reset_stage2 <= 1'b1;
      reset_stage3 <= 1'b1;
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
      valid_stage3 <= 1'b0;
    end
    else begin
      // 第一级流水线：采样输入信号
      reset_stage1 <= reset_n;
      valid_stage1 <= enable;
      
      // 第二级流水线：传递信号
      reset_stage2 <= reset_stage1;
      valid_stage2 <= valid_stage1;
      
      // 第三级流水线：用于边沿检测
      reset_stage3 <= reset_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // 流水线结果计算 - 在第三级和第二级之间检测边沿变化
  reg glitch_result;
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      glitch_result <= 1'b0;
    end
    else if (valid_stage2) begin
      // 使用异或运算检测任何变化
      glitch_result <= reset_stage2 ^ reset_stage3;
    end
  end
  
  // 输出分配
  assign glitch_detected = glitch_result;
  assign valid_out = valid_stage3;
  
endmodule