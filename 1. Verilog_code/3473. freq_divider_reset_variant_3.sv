//SystemVerilog
module freq_divider_reset #(parameter DIVISOR = 10)(
  input wire clk_in, 
  input wire reset,
  output wire clk_out
);
  
  // 定义通用分频器模块的接口信号
  wire counter_reset;
  wire counter_max;
  wire clk_toggle;
  
  // 实例化计数器子模块
  counter_module #(
    .MAX_COUNT(DIVISOR)
  ) counter_inst (
    .clk(clk_in),
    .reset(reset),
    .counter_reset(counter_reset),
    .counter_max(counter_max)
  );
  
  // 实例化时钟切换子模块
  clock_toggle_module clock_toggle_inst (
    .clk(clk_in),
    .reset(reset),
    .toggle_enable(counter_max),
    .clk_out(clk_out)
  );
  
  // 连接模块间的控制信号
  assign counter_reset = counter_max;
  
endmodule

// 计数器模块 - 重定时优化后的计数功能
module counter_module #(
  parameter MAX_COUNT = 10
)(
  input wire clk,
  input wire reset,
  input wire counter_reset,
  output wire counter_max
);
  
  // 使用clog2来确定最小计数位宽
  localparam COUNT_WIDTH = $clog2(MAX_COUNT);
  
  // 计数器寄存器
  reg [COUNT_WIDTH-1:0] counter_r;
  // 提前计算下一个计数值的组合逻辑
  wire [COUNT_WIDTH-1:0] next_counter;
  // 提前判断是否达到最大值的组合逻辑
  wire next_counter_max;
  
  // 预计算下一个计数值
  assign next_counter = (counter_r == MAX_COUNT - 1) ? {COUNT_WIDTH{1'b0}} : counter_r + 1'b1;
  // 预计算下一个周期是否达到最大值
  assign next_counter_max = (next_counter == MAX_COUNT - 1);
  
  // 重定时后的计数器逻辑
  always @(posedge clk) begin
    if (reset || counter_reset) begin
      counter_r <= {COUNT_WIDTH{1'b0}};
    end else begin
      counter_r <= next_counter;
    end
  end
  
  // 重定时后的计数器达到最大值指示信号
  assign counter_max = (counter_r == MAX_COUNT - 1);
  
endmodule

// 重定时优化后的时钟切换模块
module clock_toggle_module (
  input wire clk,
  input wire reset,
  input wire toggle_enable,
  output reg clk_out
);
  
  // 预计算下一个时钟输出值
  wire next_clk_out;
  // 寄存时钟切换使能信号
  reg toggle_enable_r;
  
  // 预计算时钟输出值的组合逻辑
  assign next_clk_out = toggle_enable_r ? ~clk_out : clk_out;
  
  // 寄存使能信号，将输入寄存器向前移动
  always @(posedge clk) begin
    if (reset) begin
      toggle_enable_r <= 1'b0;
    end else begin
      toggle_enable_r <= toggle_enable;
    end
  end
  
  // 时钟切换逻辑
  always @(posedge clk) begin
    if (reset) begin
      clk_out <= 1'b0;
    end else begin
      clk_out <= next_clk_out;
    end
  end
  
endmodule