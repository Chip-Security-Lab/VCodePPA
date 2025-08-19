//SystemVerilog
// 顶层模块
module manchester_carry_chain_adder #(
  parameter WIDTH = 8
)(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  input carry_in,
  output [WIDTH-1:0] sum,
  output carry_out
);
  wire [WIDTH:0] carry; // 额外位用于存储最终进位
  assign carry[0] = carry_in;

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : adder_gen
      // 曼彻斯特进位链加法器实现
      assign sum[i] = a[i] ^ b[i] ^ carry[i]; // 计算和
      assign carry[i + 1] = (a[i] & b[i]) | (carry[i] & (a[i] ^ b[i])); // 计算进位
    end
  endgenerate

  assign carry_out = carry[WIDTH]; // 最终进位输出
endmodule