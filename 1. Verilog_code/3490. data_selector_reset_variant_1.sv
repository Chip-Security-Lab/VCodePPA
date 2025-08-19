//SystemVerilog
`timescale 1ns / 1ps

module data_selector_reset #(parameter WIDTH = 8)(
  input clk, rst_n,
  input [WIDTH-1:0] data_a, data_b, data_c, data_d,
  input [1:0] select,
  output reg [WIDTH-1:0] data_out
);
  // 内部信号声明
  wire [1:0] subtractor_in_a;
  wire [1:0] subtractor_in_b;
  wire [1:0] subtractor_result;
  wire [WIDTH-1:0] modified_data_c;
  
  // 从输入数据中提取2位作为减法器输入
  assign subtractor_in_a = data_a[1:0];
  assign subtractor_in_b = data_b[1:0];
  
  // 实例化2位并行前缀减法器
  parallel_prefix_subtractor_2bit subtractor_inst (
    .a(subtractor_in_a),
    .b(subtractor_in_b),
    .diff(subtractor_result)
  );
  
  // 预先计算修改后的data_c
  assign modified_data_c = {data_c[WIDTH-1:2], subtractor_result};
  
  // 使用if-else结构代替条件运算符
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= {WIDTH{1'b0}};
    end else begin
      if (select == 2'b00) begin
        data_out <= data_a;
      end else if (select == 2'b01) begin
        data_out <= data_b;
      end else if (select == 2'b10) begin
        data_out <= modified_data_c;
      end else begin
        data_out <= data_d;
      end
    end
  end
endmodule

// 2位并行前缀减法器模块
module parallel_prefix_subtractor_2bit(
  input [1:0] a,
  input [1:0] b,
  output [1:0] diff
);
  // 内部信号声明
  wire [1:0] p; // 传播信号
  wire [1:0] g; // 生成信号
  wire [1:0] b_inv; // b的取反
  wire [2:0] carry; // 进位信号
  
  // 计算初始的传播和生成信号
  assign b_inv = ~b;
  assign p = a ^ b_inv;
  assign g = a & b_inv;
  
  // 设定初始进位为1（减法器需要）
  assign carry[0] = 1'b1;
  
  // 使用并行前缀计算进位
  assign carry[1] = g[0] | (p[0] & carry[0]);
  assign carry[2] = g[1] | (p[1] & carry[1]);
  
  // 计算最终差值
  assign diff = p ^ carry[1:0];
endmodule