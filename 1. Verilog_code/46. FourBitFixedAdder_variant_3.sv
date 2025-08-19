//SystemVerilog
// Top-level module for the 4-bit adder
// This module instantiates the functional submodules
module adder_14 (
    input [3:0] a,
    input [3:0] b,
    output [4:0] sum
);

  // Internal wires for connecting submodules
  wire [3:0] g_w;  // Generate signals
  wire [3:0] p_w;  // Propagate signals (OR)
  wire [3:0] pp_w; // Propagate signals (XOR)
  wire [4:0] c_w;  // Carry signals (c[i] is carry INTO bit i)

  // Assign the fixed carry-in for the LSB
  assign c_w[0] = 1'b0;

  // Instance of the GP Generator submodule
  gp_generator gp_gen_inst (
      .a_in(a),
      .b_in(b),
      .g_out(g_w),
      .p_out(p_w),
      .pp_out(pp_w)
  );

  // Instance of the Carry Lookahead Generator submodule
  carry_lookahead_generator clg_inst (
      .g_in(g_w),
      .p_in(p_w),
      .c_in(c_w[0]), // Connect the carry-in (fixed to 0)
      .c_out(c_w)    // Outputs all carries c[0] to c[4]
  );

  // Instance of the Sum Generator submodule
  sum_generator sum_gen_inst (
      .pp_in(pp_w),
      .c_in(c_w[3:0]), // Sum bits depend on carries c[0] to c[3]
      .sum_bits_out(sum[3:0]) // Outputs sum bits 0 to 3
  );

  // The final carry-out is sum[4]
  assign sum[4] = c_w[4];

endmodule

// Submodule to generate Generate (G), Propagate (P), and Propagate XOR (PP) signals
// G[i] = a[i] & b[i]
// P[i] = a[i] | b[i]
// PP[i] = a[i] ^ b[i]
module gp_generator (
    input [3:0] a_in,
    input [3:0] b_in,
    output [3:0] g_out,
    output [3:0] p_out,
    output [3:0] pp_out
);

  assign g_out = a_in & b_in;
  assign p_out = a_in | b_in;
  assign pp_out = a_in ^ b_in;

endmodule

// Submodule to calculate carries using Carry Lookahead logic
// c[i] is the carry into bit i
// Based on G and P signals from lower bits and the initial carry-in
module carry_lookahead_generator (
    input [3:0] g_in, // Generate signals from bits 0 to 3
    input [3:0] p_in, // Propagate signals from bits 0 to 3
    input       c_in, // Carry-in for bit 0 (c[0])
    output [4:0] c_out // Carries c[0] to c[4]
);

  // c[0] is the external carry-in
  assign c_out[0] = c_in;

  // Carry into bit 1 (from bit 0)
  // c[1] = g[0] | (p[0] & c[0])
  // Since c[0] is fixed to 0 here, c[1] = g[0]
  assign c_out[1] = g_in[0];

  // Carry into bit 2 (from bits 0, 1)
  // c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0])
  // Since c[0] is fixed to 0 here, c[2] = g[1] | (p[1] & g[0])
  assign c_out[2] = g_in[1] | (p_in[1] & g_in[0]);

  // Carry into bit 3 (from bits 0, 1, 2)
  // c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0])
  // Since c[0] is fixed to 0 here, c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0])
  assign c_out[3] = g_in[2] | (p_in[2] & g_in[1]) | (p_in[2] & p_in[1] & g_in[0]);

  // Carry into bit 4 (from bits 0, 1, 2, 3) - This is the final carry-out
  // c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0])
  // Since c[0] is fixed to 0 here, c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p_in[1] & g_in[0])
  assign c_out[4] = g_in[3] | (p_in[3] & g_in[2]) | (p_in[3] & p_in[2] & g_in[1]) | (p_in[3] & p_in[2] & p_in[1] & g_in[0]);

endmodule

// Submodule to calculate the sum bits
// sum[i] = pp[i] ^ c[i]
module sum_generator (
    input [3:0] pp_in,      // Propagate XOR signals from bits 0 to 3
    input [3:0] c_in,       // Carries c[0] to c[3]
    output [3:0] sum_bits_out // Sum bits 0 to 3
);

  // sum[i] = pp[i] ^ c[i]
  assign sum_bits_out = pp_in ^ c_in;

endmodule