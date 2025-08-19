//SystemVerilog
module documented_adder(
  input signed [7:0] operand_x,
  input signed [7:0] operand_y,
  output signed [8:0] sum_result
);

  // 子模块：带状进位加法器
  carry_select_adder u_carry_select_adder(
    .x(operand_x),
    .y(operand_y),
    .sum(sum_result)
  );

endmodule

module carry_select_adder(
  input signed [7:0] x,
  input signed [7:0] y,
  output signed [8:0] sum
);

  // 生成进位信号
  wire [7:0] g = x & y;  // 生成信号
  wire [7:0] p = x ^ y;  // 传播信号
  
  // 计算进位链
  wire [8:0] c;
  assign c[0] = 1'b0;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  assign c[8] = g[7] | (p[7] & c[7]);
  
  // 计算最终和
  assign sum = {c[8], p ^ c[7:0]};

endmodule