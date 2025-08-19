//SystemVerilog
`timescale 1ns / 1ps
module async_reset_counter #(
  parameter WIDTH = 16
)(
  input wire clk,       // 时钟输入
  input wire rst_n,     // 低电平有效异步复位
  input wire enable,    // 计数使能
  output reg [WIDTH-1:0] counter  // 计数器输出
);

  // 内部计数值寄存器（重定时后的寄存器）
  reg [WIDTH-1:0] counter_next;
  
  // 计算下一个计数值的组合逻辑
  wire [WIDTH-1:0] counter_plus_one;
  assign counter_plus_one = counter + 1'b1;
  
  // 第一阶段：计算下一个计数值并存储到寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_next <= {WIDTH{1'b0}};
    end
    else if (enable) begin
      counter_next <= counter_plus_one;
    end
  end
  
  // 第二阶段：将计算结果传递到输出寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= {WIDTH{1'b0}};
    end
    else begin
      counter <= counter_next;
    end
  end

endmodule