//SystemVerilog
// Han-Carlson Adder Top Module
module reverse_add(
  input [0:3] vectorA,  //MSB first
  input [0:3] vectorB,
  output [0:4] result
);

  wire [0:3] g, p;
  wire [0:3] g1, p1;
  wire [0:3] g2, p2;
  wire [0:3] g3, p3;
  wire [0:3] c;

  // Generate and Propagate Module
  gp_generator gp_gen(
    .vectorA(vectorA),
    .vectorB(vectorB),
    .g(g),
    .p(p)
  );

  // First Level Prefix Module
  prefix_level1 level1(
    .g(g),
    .p(p),
    .g1(g1),
    .p1(p1)
  );

  // Second Level Prefix Module
  prefix_level2 level2(
    .g1(g1),
    .p1(p1),
    .g2(g2),
    .p2(p2)
  );

  // Third Level Prefix Module
  prefix_level3 level3(
    .g2(g2),
    .p2(p2),
    .g3(g3),
    .p3(p3)
  );

  // Carry and Sum Module
  carry_sum_gen cs_gen(
    .g3(g3),
    .p(p),
    .c(c),
    .result(result)
  );

endmodule

// Generate and Propagate Module
module gp_generator(
  input [0:3] vectorA,
  input [0:3] vectorB,
  output [0:3] g,
  output [0:3] p
);
  assign g = vectorA & vectorB;
  assign p = vectorA ^ vectorB;
endmodule

// First Level Prefix Module
module prefix_level1(
  input [0:3] g,
  input [0:3] p,
  output [0:3] g1,
  output [0:3] p1
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

// Second Level Prefix Module
module prefix_level2(
  input [0:3] g1,
  input [0:3] p1,
  output [0:3] g2,
  output [0:3] p2
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

// Third Level Prefix Module
module prefix_level3(
  input [0:3] g2,
  input [0:3] p2,
  output [0:3] g3,
  output [0:3] p3
);
  assign g3[0] = g2[0];
  assign p3[0] = p2[0];
  assign g3[1] = g2[1];
  assign p3[1] = p2[1];
  assign g3[2] = g2[2];
  assign p3[2] = p2[2];
  assign g3[3] = g2[3] | (p2[3] & g2[2]);
  assign p3[3] = p2[3] & p2[2];
endmodule

// Carry and Sum Generation Module
module carry_sum_gen(
  input [0:3] g3,
  input [0:3] p,
  output [0:3] c,
  output [0:4] result
);
  assign c[0] = 1'b0;
  assign c[1] = g3[0];
  assign c[2] = g3[1];
  assign c[3] = g3[2];
  
  assign result[0] = p[0] ^ c[0];
  assign result[1] = p[1] ^ c[1];
  assign result[2] = p[2] ^ c[2];
  assign result[3] = p[3] ^ c[3];
  assign result[4] = g3[3];
endmodule