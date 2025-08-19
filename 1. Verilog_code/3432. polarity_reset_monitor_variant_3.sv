//SystemVerilog
module polarity_reset_monitor #(
  parameter ACTIVE_HIGH = 1
) (
  input  wire clk,
  input  wire reset_in,
  output wire reset_out
);
  // 第一阶段：输入捕获和极性转换
  reg  reset_in_stage1;
  wire normalized_reset_stage1;
  
  // 第二阶段：同步处理
  reg  normalized_reset_stage2;
  
  // 第三阶段：进一步同步和去除亚稳态
  reg  normalized_reset_stage3;
  
  // 第四阶段：输出极性恢复
  reg  reset_out_stage4;
  
  // 第一阶段流水线逻辑 - 输入捕获和标准化
  always @(posedge clk) begin
    reset_in_stage1 <= reset_in;
  end
  assign normalized_reset_stage1 = ACTIVE_HIGH ? reset_in_stage1 : ~reset_in_stage1;
  
  // 第二阶段流水线逻辑 - 同步处理第一级
  always @(posedge clk) begin
    normalized_reset_stage2 <= normalized_reset_stage1;
  end
  
  // 第三阶段流水线逻辑 - 同步处理第二级
  always @(posedge clk) begin
    normalized_reset_stage3 <= normalized_reset_stage2;
  end
  
  // 第四阶段流水线逻辑 - 输出极性恢复
  always @(posedge clk) begin
    reset_out_stage4 <= ACTIVE_HIGH ? normalized_reset_stage3 : ~normalized_reset_stage3;
  end
  
  // 输出驱动
  assign reset_out = reset_out_stage4;
  
endmodule