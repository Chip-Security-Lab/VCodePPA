//SystemVerilog
module reset_generator_debounce #(parameter DEBOUNCE_LEN = 4)(
  input wire clk, 
  input wire button_in,
  output reg reset_out
);

  // 流水线寄存器定义
  reg [DEBOUNCE_LEN-1:0] debounce_stage1;
  reg button_in_stage1, button_in_stage2, button_in_stage3;
  
  // 用于检测全1和全0的计数器
  reg [7:0] ones_count, zeros_count;
  wire [7:0] ones_threshold, zeros_threshold;
  
  // 设置阈值
  assign ones_threshold = 8'd16;  // 全1需要达到的阈值
  assign zeros_threshold = 8'd16; // 全0需要达到的阈值
  
  // 用于检测状态的信号
  reg all_ones_detected, all_zeros_detected;
  wire [7:0] ones_diff, zeros_diff;
  wire [7:0] ones_comp, zeros_comp;
  
  // 第一级流水线：采样输入和移位寄存器操作
  always @(posedge clk) begin
    button_in_stage1 <= button_in;
    debounce_stage1 <= {debounce_stage1[DEBOUNCE_LEN-2:0], button_in_stage1};
  end

  // 计算当前1和0的数量
  always @(posedge clk) begin
    button_in_stage2 <= button_in_stage1;
    ones_count <= &debounce_stage1 ? ones_count + 8'd1 : 8'd0;
    zeros_count <= ~|debounce_stage1 ? zeros_count + 8'd1 : 8'd0;
  end
  
  // 使用补码加法实现减法 (ones_diff = ones_threshold - ones_count)
  assign ones_comp = ~ones_count + 8'd1;  // 求ones_count的补码
  assign ones_diff = ones_threshold + ones_comp;  // 等价于ones_threshold - ones_count
  
  // 使用补码加法实现减法 (zeros_diff = zeros_threshold - zeros_count)
  assign zeros_comp = ~zeros_count + 8'd1;  // 求zeros_count的补码
  assign zeros_diff = zeros_threshold + zeros_comp;  // 等价于zeros_threshold - zeros_count
  
  // 检测阈值条件
  always @(posedge clk) begin
    button_in_stage3 <= button_in_stage2;
    all_ones_detected <= (ones_diff == 8'd0 || ones_count >= ones_threshold);
    all_zeros_detected <= (zeros_diff == 8'd0 || zeros_count >= zeros_threshold);
  end
  
  // 输出阶段 - 使用case语句
  always @(posedge clk) begin
    // 将检测条件转换为2位控制信号
    case ({all_ones_detected, all_zeros_detected})
      2'b10:   reset_out <= 1'b1;  // 全1情况
      2'b01:   reset_out <= 1'b0;  // 全0情况
      default: reset_out <= reset_out;  // 保持原值
    endcase
  end

endmodule