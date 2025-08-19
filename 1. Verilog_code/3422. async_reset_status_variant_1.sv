//SystemVerilog
module async_reset_status (
  input wire clk,
  input wire reset,
  output wire reset_active,
  output reg [3:0] reset_count_stage3
);
  // 流水线寄存器 - 第一级
  reg reset_detected_stage1;
  reg [3:0] next_count;
  
  // 流水线寄存器 - 第二级
  reg reset_detected_stage2;
  reg [3:0] reset_count_stage2;
  
  // 组合逻辑计算下一个计数值
  always @(*) begin
    if (reset_count_stage3 < 4'hF)
      next_count = reset_count_stage3 + 4'd1;
    else
      next_count = reset_count_stage3;
  end
  
  // 将复位信号直接输出
  assign reset_active = reset;
  
  // 流水线第一级 - 检测复位和初始计数
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      reset_detected_stage1 <= 1'b1;
    end
    else begin
      reset_detected_stage1 <= 1'b0;
    end
  end
  
  // 流水线第二级 - 传递状态
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      reset_detected_stage2 <= 1'b1;
    end
    else begin
      reset_detected_stage2 <= reset_detected_stage1;
    end
  end
  
  // 重定时后的计数逻辑 - 直接接收组合逻辑的结果
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      reset_count_stage2 <= 4'd0;
      reset_count_stage3 <= 4'd0;
    end
    else begin
      reset_count_stage2 <= next_count;
      if (reset_detected_stage2)
        reset_count_stage3 <= 4'd0;
      else
        reset_count_stage3 <= reset_count_stage2;
    end
  end
endmodule