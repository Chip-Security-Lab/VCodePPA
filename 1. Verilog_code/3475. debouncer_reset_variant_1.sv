//SystemVerilog
// 顶层模块
module debouncer_reset #(
  parameter DELAY = 16
)(
  input  wire clk,        // 时钟输入
  input  wire rst,        // 复位信号
  input  wire button_in,  // 按键输入
  output wire button_out  // 消抖后的按键输出
);

  // 内部连线
  wire [DELAY-1:0] shift_reg_value;
  wire all_ones, all_zeros;

  // 按键状态采样子模块实例
  button_sampler #(
    .DELAY(DELAY)
  ) u_button_sampler (
    .clk        (clk),
    .rst        (rst),
    .button_in  (button_in),
    .shift_reg  (shift_reg_value)
  );

  // 采样值判断子模块实例
  sample_evaluator #(
    .DELAY(DELAY)
  ) u_sample_evaluator (
    .shift_reg  (shift_reg_value),
    .all_ones   (all_ones),
    .all_zeros  (all_zeros)
  );

  // 输出逻辑子模块实例
  output_controller u_output_controller (
    .clk        (clk),
    .rst        (rst),
    .all_ones   (all_ones),
    .all_zeros  (all_zeros),
    .button_out (button_out)
  );

endmodule

// 按键状态采样子模块：负责采样按键输入并构建移位寄存器
module button_sampler #(
  parameter DELAY = 16
)(
  input  wire clk,                 // 时钟输入
  input  wire rst,                 // 复位信号
  input  wire button_in,           // 按键输入
  output reg  [DELAY-1:0] shift_reg // 移位寄存器输出
);

  // 复位处理
  always @(posedge clk) begin
    if (rst) begin
      shift_reg <= {DELAY{1'b0}};
    end
  end
  
  // 移位寄存器更新
  always @(posedge clk) begin
    if (!rst) begin
      shift_reg <= {shift_reg[DELAY-2:0], button_in};
    end
  end

endmodule

// 采样值判断子模块：检测移位寄存器中的全1或全0状态
module sample_evaluator #(
  parameter DELAY = 16
)(
  input  wire [DELAY-1:0] shift_reg, // 移位寄存器输入
  output wire all_ones,              // 全1指示
  output wire all_zeros              // 全0指示
);

  assign all_ones  = &shift_reg;    // 移位寄存器全1
  assign all_zeros = ~|shift_reg;   // 移位寄存器全0

endmodule

// 输出逻辑子模块：根据评估结果产生最终的输出
module output_controller (
  input  wire clk,        // 时钟输入
  input  wire rst,        // 复位信号
  input  wire all_ones,   // 全1指示输入
  input  wire all_zeros,  // 全0指示输入
  output reg  button_out  // 消抖后的按键输出
);

  // 复位处理
  always @(posedge clk) begin
    if (rst) begin
      button_out <= 1'b0;
    end
  end
  
  // 设置按键为高电平
  always @(posedge clk) begin
    if (!rst && all_ones) begin
      button_out <= 1'b1;
    end
  end
  
  // 设置按键为低电平
  always @(posedge clk) begin
    if (!rst && all_zeros) begin
      button_out <= 1'b0;
    end
  end

endmodule