//SystemVerilog
module documented_adder(
  input signed [7:0] operand_x,
  input signed [7:0] operand_y,
  output signed [8:0] sum_result
);

  carry_lookahead_adder u_adder_core(
    .in_a(operand_x),
    .in_b(operand_y),
    .sum(sum_result)
  );

endmodule

module carry_lookahead_adder(
  input signed [7:0] in_a,
  input signed [7:0] in_b,
  output signed [8:0] sum
);

  wire [7:0] g, p;
  wire [7:0] c;
  
  assign g = in_a & in_b;
  assign p = in_a ^ in_b;
  
  assign c[0] = 1'b0;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  
  assign sum[0] = p[0] ^ c[0];
  assign sum[1] = p[1] ^ c[1];
  assign sum[2] = p[2] ^ c[2];
  assign sum[3] = p[3] ^ c[3];
  assign sum[4] = p[4] ^ c[4];
  assign sum[5] = p[5] ^ c[5];
  assign sum[6] = p[6] ^ c[6];
  assign sum[7] = p[7] ^ c[7];
  assign sum[8] = g[7] | (p[7] & c[7]);

endmodule