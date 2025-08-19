//SystemVerilog
// Top level module
module reverse_add(
  input [0:3] vectorA,
  input [0:3] vectorB, 
  output [0:4] result
);

  // Internal signals
  wire [0:3] g, p;
  wire c1, c2, c3, c4;

  // Instantiate generate/propagate module
  gp_gen gp_gen_inst(
    .vectorA(vectorA),
    .vectorB(vectorB),
    .g(g),
    .p(p)
  );

  // Instantiate carry lookahead module  
  carry_lookahead carry_lookahead_inst(
    .g(g),
    .p(p),
    .c1(c1),
    .c2(c2), 
    .c3(c3),
    .c4(c4)
  );

  // Instantiate sum calculation module
  sum_calc sum_calc_inst(
    .p(p),
    .c1(c1),
    .c2(c2),
    .c3(c3),
    .c4(c4),
    .result(result)
  );

endmodule

// Generate and propagate module
module gp_gen(
  input [0:3] vectorA,
  input [0:3] vectorB,
  output [0:3] g,
  output [0:3] p
);
  assign g = vectorA & vectorB;
  assign p = vectorA ^ vectorB;
endmodule

// Carry lookahead module
module carry_lookahead(
  input [0:3] g,
  input [0:3] p,
  output c1,
  output c2,
  output c3,
  output c4
);
  assign c1 = g[0] | (p[0] & 1'b0);
  assign c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & 1'b0);
  assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & 1'b0);
  assign c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & 1'b0);
endmodule

// Sum calculation module
module sum_calc(
  input [0:3] p,
  input c1,
  input c2,
  input c3,
  input c4,
  output [0:4] result
);
  assign result[0] = p[0];
  assign result[1] = p[1] ^ c1;
  assign result[2] = p[2] ^ c2;
  assign result[3] = p[3] ^ c3;
  assign result[4] = c4;
endmodule