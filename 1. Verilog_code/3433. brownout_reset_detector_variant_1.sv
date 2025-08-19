//SystemVerilog
module brownout_reset_detector #(
  parameter THRESHOLD = 8'h80
) (
  input wire clk,
  input wire [7:0] voltage_level,
  output reg brownout_reset
);
  // 流水线阶段1：电压比较
  wire voltage_below_threshold_stage1;
  reg voltage_below_threshold_stage2;
  
  // 流水线阶段2：状态检测
  reg voltage_below_threshold_stage3;
  reg voltage_state_stage3;
  
  // 流水线阶段3：状态转换
  reg voltage_below_threshold_stage4;
  reg voltage_state_stage4;
  
  // 流水线阶段4：生成复位信号
  reg voltage_below_threshold_stage5;
  reg voltage_state_stage5;
  
  // 将比较逻辑提前，减少输入到第一级寄存器的延迟
  assign voltage_below_threshold_stage1 = voltage_level < THRESHOLD;
  
  always @(posedge clk) begin
    // 流水线阶段1输出寄存
    voltage_below_threshold_stage2 <= voltage_below_threshold_stage1;
    
    // 流水线阶段2输出寄存
    voltage_below_threshold_stage3 <= voltage_below_threshold_stage2;
    voltage_state_stage3 <= voltage_below_threshold_stage2;
    
    // 流水线阶段3输出寄存
    voltage_below_threshold_stage4 <= voltage_below_threshold_stage3;
    voltage_state_stage4 <= voltage_state_stage3;
    
    // 流水线阶段4输出寄存
    voltage_below_threshold_stage5 <= voltage_below_threshold_stage4;
    voltage_state_stage5 <= voltage_state_stage4;
    
    // 输出寄存 - 最终阶段
    brownout_reset <= voltage_state_stage5 & voltage_below_threshold_stage5;
  end
endmodule