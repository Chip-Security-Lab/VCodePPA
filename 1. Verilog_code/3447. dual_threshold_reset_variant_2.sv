//SystemVerilog
//============================================================================
//============================================================================
module dual_threshold_reset (
  input wire clk,
  input wire [7:0] level,
  input wire [7:0] upper_threshold,
  input wire [7:0] lower_threshold,
  output reg reset_out
);

  // 直接比较逻辑
  wire level_exceeded_upper;
  wire level_below_lower;
  
  // 寄存阈值信号 - 将寄存器移到组合逻辑之前
  reg [7:0] level_reg;
  reg [7:0] upper_threshold_reg;
  reg [7:0] lower_threshold_reg;

  // 状态信号
  reg reset_state;

  // 将输入信号寄存 - 重定时优化
  always @(posedge clk) begin
    level_reg <= level;
    upper_threshold_reg <= upper_threshold;
    lower_threshold_reg <= lower_threshold;
  end

  // 使用寄存的值进行比较
  assign level_exceeded_upper = (level_reg > upper_threshold_reg);
  assign level_below_lower = (level_reg < lower_threshold_reg);

  // 重置控制逻辑 - 基于比较结果直接产生输出
  always @(posedge clk) begin
    // 当未处于重置状态且超过上阈值时，激活重置信号
    if (!reset_out && level_exceeded_upper)
      reset_out <= 1'b1;
    // 当处于重置状态且低于下阈值时，解除重置信号
    else if (reset_out && level_below_lower)
      reset_out <= 1'b0;
    // 其他情况保持当前状态
  end

endmodule