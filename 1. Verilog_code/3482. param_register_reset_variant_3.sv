//SystemVerilog
module param_register_reset #(
  parameter WIDTH = 16,
  parameter RESET_VALUE = 16'hFFFF
)(
  input clk, rst_n, load,
  input [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out
);
  // 8位并行前缀减法器结果
  wire [7:0] subtractor_result;
  
  // 实例化优化后的减法器模块
  parallel_prefix_subtractor_8bit subtractor_inst (
    .a(data_in[7:0]),
    .b(data_in[15:8]),
    .diff(subtractor_result)
  );
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_out <= RESET_VALUE;
    else if (load) begin
      // 使用减法器结果
      data_out[7:0] <= subtractor_result;
      data_out[WIDTH-1:8] <= data_in[WIDTH-1:8];
    end
  end
endmodule

// 优化的8位并行前缀减法器
module parallel_prefix_subtractor_8bit (
  input [7:0] a,
  input [7:0] b,
  output [7:0] diff
);
  wire [7:0] b_neg;
  wire [7:0] p, g;
  wire [7:0] carry;
  
  // 对b取反 (一步完成二进制补码)
  assign b_neg = ~b + 8'h01;
  
  // 生成传播和生成信号
  assign p = a ^ b_neg;
  assign g = a & b_neg;
  
  // 使用优化的Kogge-Stone前缀结构计算进位
  // 直接合并多层前缀计算，减少中间变量
  
  // 第1位进位就是g[0]
  assign carry[0] = g[0];
  
  // 优化后的第2位进位
  assign carry[1] = g[1] | (p[1] & g[0]);
  
  // 优化后的第3位进位
  assign carry[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
  
  // 优化后的第4位进位
  assign carry[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
  
  // 优化后的第5位进位
  assign carry[4] = g[4] | (p[4] & carry[3]);
  
  // 优化后的第6位进位
  assign carry[5] = g[5] | (p[5] & carry[4]);
  
  // 优化后的第7位进位
  assign carry[6] = g[6] | (p[6] & carry[5]);
  
  // 优化后的第8位进位 (不需用于输出)
  assign carry[7] = g[7] | (p[7] & carry[6]);
  
  // 计算结果 - 第0位直接使用p[0]
  assign diff[0] = p[0];
  
  // 其他位使用传播信号异或前一位的进位
  assign diff[7:1] = p[7:1] ^ carry[6:0];
endmodule