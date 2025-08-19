//SystemVerilog
module lfsr_with_reset #(parameter WIDTH = 8)(
  input clk, async_rst, enable,
  input data_valid_in,             // 数据有效输入信号
  output reg data_valid_out,       // 数据有效输出信号
  output reg [WIDTH-1:0] lfsr_out
);

  // 流水线阶段1：缓存输入
  reg [WIDTH-1:0] lfsr_stage1;
  reg data_valid_stage1;
  
  // 流水线阶段2：计算反馈部分1
  reg [WIDTH-1:0] lfsr_stage2;
  reg data_valid_stage2;
  reg feedback_part1_stage2;
  
  // 流水线阶段3：计算反馈部分2
  reg [WIDTH-1:0] lfsr_stage3;
  reg data_valid_stage3;
  reg feedback_part1_stage3;
  reg feedback_part2_stage3;
  
  // 流水线阶段4：完成反馈计算
  reg [WIDTH-1:0] lfsr_stage4;
  reg data_valid_stage4;
  reg feedback_stage4;
  
  // 流水线阶段5：执行移位操作
  reg [WIDTH-1:0] lfsr_stage5;
  reg data_valid_stage5;
  
  // 反馈计算拆分为更小的单元
  wire feedback_part1 = lfsr_stage1[7] ^ lfsr_stage1[3];
  wire feedback_part2 = lfsr_stage2[2] ^ lfsr_stage2[1];
  wire feedback = feedback_part1_stage3 ^ feedback_part2_stage3;
  
  // 预计算下一个阶段的移位结果
  wire [WIDTH-1:0] shifted_value = {lfsr_stage4[WIDTH-2:0], feedback_stage4};
  
  // 流水线阶段1 - 缓存输入
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_stage1 <= 8'h01;  // 非零种子
      data_valid_stage1 <= 1'b0;
    end
    else if (enable) begin
      lfsr_stage1 <= lfsr_out;
      data_valid_stage1 <= data_valid_in;
    end
  end
  
  // 流水线阶段2 - 计算反馈部分1
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_stage2 <= 8'h01;
      data_valid_stage2 <= 1'b0;
      feedback_part1_stage2 <= 1'b0;
    end
    else if (enable) begin
      lfsr_stage2 <= lfsr_stage1;
      data_valid_stage2 <= data_valid_stage1;
      feedback_part1_stage2 <= feedback_part1;
    end
  end
  
  // 流水线阶段3 - 计算反馈部分2
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_stage3 <= 8'h01;
      data_valid_stage3 <= 1'b0;
      feedback_part1_stage3 <= 1'b0;
      feedback_part2_stage3 <= 1'b0;
    end
    else if (enable) begin
      lfsr_stage3 <= lfsr_stage2;
      data_valid_stage3 <= data_valid_stage2;
      feedback_part1_stage3 <= feedback_part1_stage2;
      feedback_part2_stage3 <= feedback_part2;
    end
  end
  
  // 流水线阶段4 - 完成反馈计算
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_stage4 <= 8'h01;
      data_valid_stage4 <= 1'b0;
      feedback_stage4 <= 1'b0;
    end
    else if (enable) begin
      lfsr_stage4 <= lfsr_stage3;
      data_valid_stage4 <= data_valid_stage3;
      feedback_stage4 <= feedback;
    end
  end
  
  // 流水线阶段5 - 执行移位
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_stage5 <= 8'h01;
      data_valid_stage5 <= 1'b0;
    end
    else if (enable) begin
      lfsr_stage5 <= shifted_value;
      data_valid_stage5 <= data_valid_stage4;
    end
  end
  
  // 输出阶段
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      lfsr_out <= 8'h01;  // 非零种子
      data_valid_out <= 1'b0;
    end
    else if (enable) begin
      lfsr_out <= lfsr_stage5;
      data_valid_out <= data_valid_stage5;
    end
  end

endmodule