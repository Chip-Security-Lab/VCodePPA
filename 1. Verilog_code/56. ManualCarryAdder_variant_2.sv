//SystemVerilog
// Top-level module
module multi_assign(
  input [3:0] val1, val2,
  output [4:0] sum,
  output carry
);

  // Internal signals
  wire [3:0] g, p;
  wire [3:0] g1, p1;
  wire [3:0] g2, p2;
  wire [4:0] c;

  // Generate and propagate module
  gp_gen gp_inst(
    .val1(val1),
    .val2(val2),
    .g(g),
    .p(p)
  );

  // First level carry lookahead
  cla_level1 cla1_inst(
    .g(g),
    .p(p),
    .g1(g1),
    .p1(p1)
  );

  // Second level carry lookahead
  cla_level2 cla2_inst(
    .g1(g1),
    .p1(p1),
    .g2(g2),
    .p2(p2)
  );

  // Carry computation module
  carry_gen carry_inst(
    .g2(g2),
    .c(c)
  );

  // Sum computation module
  sum_gen sum_inst(
    .p(p),
    .c(c),
    .sum(sum)
  );

  assign carry = c[4];

endmodule

// Generate and propagate module
module gp_gen(
  input [3:0] val1, val2,
  output [3:0] g, p
);
  assign g = val1 & val2;
  assign p = val1 ^ val2;
endmodule

// First level carry lookahead module
module cla_level1(
  input [3:0] g, p,
  output [3:0] g1, p1
);
  assign g1[0] = g[0];
  assign p1[0] = p[0];
  assign g1[1] = g[1] | (p[1] & g[0]);
  assign p1[1] = p[1] & p[0];
  assign g1[2] = g[2] | (p[2] & g[1]);
  assign p1[2] = p[2] & p[1];
  assign g1[3] = g[3] | (p[3] & g[2]);
  assign p1[3] = p[3] & p[2];
endmodule

// Second level carry lookahead module
module cla_level2(
  input [3:0] g1, p1,
  output [3:0] g2, p2
);
  assign g2[0] = g1[0];
  assign p2[0] = p1[0];
  assign g2[1] = g1[1];
  assign p2[1] = p1[1];
  assign g2[2] = g1[2] | (p1[2] & g1[0]);
  assign p2[2] = p1[2] & p1[0];
  assign g2[3] = g1[3] | (p1[3] & g1[1]);
  assign p2[3] = p1[3] & p1[1];
endmodule

// Carry computation module
module carry_gen(
  input [3:0] g2,
  output [4:0] c
);
  assign c[0] = 1'b0;
  assign c[1] = g2[0];
  assign c[2] = g2[1];
  assign c[3] = g2[2];
  assign c[4] = g2[3];
endmodule

// Sum computation module
module sum_gen(
  input [3:0] p,
  input [4:0] c,
  output [4:0] sum
);
  assign sum[0] = p[0] ^ c[0];
  assign sum[1] = p[1] ^ c[1];
  assign sum[2] = p[2] ^ c[2];
  assign sum[3] = p[3] ^ c[3];
  assign sum[4] = c[4];
endmodule