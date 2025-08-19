//SystemVerilog
// Top level module
module alias_add(
  input [5:0] primary,
  input [5:0] secondary,
  output [6:0] aggregate
);

  // Internal signals
  wire [5:0] operand_A;
  wire [5:0] operand_B;
  wire [5:0] p;  // Propagate signals
  wire [5:0] g;  // Generate signals
  wire [5:0] c;  // Carry signals
  wire [5:0] s;  // Sum signals
  
  // Input processing submodule
  input_processor u_input_processor(
    .primary(primary),
    .secondary(secondary),
    .operand_A(operand_A),
    .operand_B(operand_B)
  );

  // Propagate and generate signals submodule
  pg_generator u_pg_generator(
    .operand_A(operand_A),
    .operand_B(operand_B),
    .p(p),
    .g(g)
  );

  // Carry chain submodule
  carry_chain u_carry_chain(
    .p(p),
    .g(g),
    .c(c)
  );

  // Sum calculation submodule
  sum_calculator u_sum_calculator(
    .p(p),
    .c(c),
    .s(s)
  );

  // Final sum with carry out
  assign aggregate = {c[5], s};

endmodule

// Input processing submodule
module input_processor(
  input [5:0] primary,
  input [5:0] secondary,
  output [5:0] operand_A,
  output [5:0] operand_B
);
  assign operand_A = primary;
  assign operand_B = secondary;
endmodule

// Propagate and generate signals submodule
module pg_generator(
  input [5:0] operand_A,
  input [5:0] operand_B,
  output [5:0] p,
  output [5:0] g
);
  genvar i;
  generate
    for(i=0; i<6; i=i+1) begin: gen_prop
      assign p[i] = operand_A[i] ^ operand_B[i];
      assign g[i] = operand_A[i] & operand_B[i];
    end
  endgenerate
endmodule

// Carry chain submodule
module carry_chain(
  input [5:0] p,
  input [5:0] g,
  output [5:0] c
);
  assign c[0] = 1'b0;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
  assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
endmodule

// Sum calculation submodule
module sum_calculator(
  input [5:0] p,
  input [5:0] c,
  output [5:0] s
);
  assign s[0] = p[0] ^ c[0];
  assign s[1] = p[1] ^ c[1];
  assign s[2] = p[2] ^ c[2];
  assign s[3] = p[3] ^ c[3];
  assign s[4] = p[4] ^ c[4];
  assign s[5] = p[5] ^ c[5];
endmodule