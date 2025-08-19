//SystemVerilog
module brownout_reset_detector #(
  parameter THRESHOLD = 8'h80
) (
  input wire clk,
  input wire rst_n,
  input wire [7:0] voltage_level,
  input wire valid_in,
  output reg valid_out,
  output reg brownout_reset
);
  // 流水线寄存器声明
  // 阶段1寄存器
  reg [7:0] voltage_level_stage1;
  reg valid_stage1;
  
  // 阶段2寄存器
  reg voltage_below_threshold_stage2;
  reg valid_stage2;
  reg voltage_state_stage2;
  
  // 阶段3寄存器
  reg voltage_below_threshold_stage3;
  reg voltage_state_stage3;
  reg valid_stage3;
  
  // 组合逻辑信号声明
  wire voltage_below_threshold_stage1;
  wire brownout_reset_comb;
  
  // 组合逻辑部分
  // 阶段1: 电压比较
  assign voltage_below_threshold_stage1 = voltage_level_stage1 < THRESHOLD;
  
  // 输出生成组合逻辑
  assign brownout_reset_comb = voltage_below_threshold_stage3 & voltage_state_stage3;
  
  // 时序逻辑部分
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有流水线寄存器
      voltage_level_stage1 <= 8'h0;
      valid_stage1 <= 1'b0;
      
      voltage_below_threshold_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
      voltage_state_stage2 <= 1'b0;
      
      voltage_below_threshold_stage3 <= 1'b0;
      voltage_state_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
      
      valid_out <= 1'b0;
      brownout_reset <= 1'b0;
    end
    else begin
      // 阶段1: 输入寄存
      voltage_level_stage1 <= voltage_level;
      valid_stage1 <= valid_in;
      
      // 阶段2: 保存比较结果和状态
      voltage_below_threshold_stage2 <= voltage_below_threshold_stage1;
      valid_stage2 <= valid_stage1;
      voltage_state_stage2 <= voltage_below_threshold_stage2;
      
      // 阶段3: 准备输出
      voltage_below_threshold_stage3 <= voltage_below_threshold_stage2;
      voltage_state_stage3 <= voltage_state_stage2;
      valid_stage3 <= valid_stage2;
      
      // 输出阶段
      valid_out <= valid_stage3;
      brownout_reset <= brownout_reset_comb;
    end
  end
endmodule