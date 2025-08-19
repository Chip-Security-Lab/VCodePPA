//SystemVerilog
module brownout_reset_detector #(
  parameter THRESHOLD = 8'h80
) (
  input  wire       clk,
  input  wire       rst_n,
  input  wire [7:0] voltage_level,
  output wire       brownout_reset
);
  // 分解电压比较阶段
  reg  [7:0] voltage_level_stage1;  // 数据流阶段1：寄存输入电压
  reg  comp_result_stage2;          // 数据流阶段2：比较结果
  
  // 扩展持续性检测
  reg  comp_result_stage3;          // 数据流阶段3：延迟比较结果1
  reg  comp_result_stage4;          // 数据流阶段4：延迟比较结果2
  reg  comp_result_stage5;          // 数据流阶段5：延迟比较结果3
  
  // 复位信号生成阶段
  reg  pre_reset_stage6;            // 数据流阶段6：预复位信号
  reg  brownout_reset_stage7;       // 数据流阶段7：最终复位信号

  // 数据流通路 - 第1级：输入电压寄存
  always @(posedge clk)
    voltage_level_stage1 <= !rst_n ? 8'hFF : voltage_level;

  // 数据流通路 - 第2级：电压比较
  always @(posedge clk)
    comp_result_stage2 <= !rst_n ? 1'b0 : (voltage_level_stage1 < THRESHOLD);

  // 数据流通路 - 第3级：持续性检测1
  always @(posedge clk)
    comp_result_stage3 <= !rst_n ? 1'b0 : comp_result_stage2;

  // 数据流通路 - 第4级：持续性检测2
  always @(posedge clk)
    comp_result_stage4 <= !rst_n ? 1'b0 : comp_result_stage3;

  // 数据流通路 - 第5级：持续性检测3
  always @(posedge clk)
    comp_result_stage5 <= !rst_n ? 1'b0 : comp_result_stage4;

  // 数据流通路 - 第6级：预复位信号生成
  always @(posedge clk)
    pre_reset_stage6 <= !rst_n ? 1'b0 : (comp_result_stage2 & comp_result_stage3 & 
                                         comp_result_stage4 & comp_result_stage5);

  // 数据流通路 - 第7级：最终复位信号生成
  always @(posedge clk)
    brownout_reset_stage7 <= !rst_n ? 1'b0 : pre_reset_stage6;

  // 输出赋值
  assign brownout_reset = brownout_reset_stage7;

endmodule