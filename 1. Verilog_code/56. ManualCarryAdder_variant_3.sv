//SystemVerilog
// Top level module
module multi_assign(
  input [3:0] val1, val2,
  output [4:0] sum,
  output carry
);

  // Generate and propagate signals
  wire [3:0] g, p;
  gp_generator gp_gen(
    .val1(val1),
    .val2(val2),
    .g(g),
    .p(p)
  );

  // First level prefix computation
  wire [3:0] g1, p1;
  prefix_level1 prefix1(
    .g(g),
    .p(p),
    .g1(g1),
    .p1(p1)
  );

  // Second level prefix computation
  wire [3:0] g2, p2;
  prefix_level2 prefix2(
    .g1(g1),
    .p1(p1),
    .g2(g2),
    .p2(p2)
  );

  // Final sum computation
  wire [3:0] c;
  sum_computer sum_comp(
    .g2(g2),
    .p(p),
    .c(c),
    .sum(sum)
  );

  assign carry = sum[4];

endmodule

// Generate and propagate signals generator
module gp_generator(
  input [3:0] val1, val2,
  output [3:0] g, p
);
  assign g = val1 & val2;
  assign p = val1 ^ val2;
endmodule

// First level prefix computation
module prefix_level1(
  input [3:0] g, p,
  output [3:0] g1, p1
);
  assign g1[0] = g[0];
  assign p1[0] = p[0];
  
  genvar i;
  generate
    for(i=1; i<4; i=i+1) begin: gen_first_level
      assign g1[i] = g[i] | (p[i] & g[i-1]);
      assign p1[i] = p[i] & p[i-1];
    end
  endgenerate
endmodule

// Second level prefix computation
module prefix_level2(
  input [3:0] g1, p1,
  output [3:0] g2, p2
);
  assign g2[0] = g1[0];
  assign p2[0] = p1[0];
  assign g2[1] = g1[1];
  assign p2[1] = p1[1];
  
  genvar i;
  generate
    for(i=2; i<4; i=i+1) begin: gen_second_level
      assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
      assign p2[i] = p1[i] & p1[i-2];
    end
  endgenerate
endmodule

// Final sum computation
module sum_computer(
  input [3:0] g2, p,
  output [3:0] c,
  output [4:0] sum
);
  assign c[0] = 1'b0;
  assign c[1] = g2[0];
  assign c[2] = g2[1];
  assign c[3] = g2[2];
  
  assign sum[0] = p[0];
  assign sum[1] = p[1] ^ c[1];
  assign sum[2] = p[2] ^ c[2];
  assign sum[3] = p[3] ^ c[3];
  assign sum[4] = g2[3];
endmodule