//SystemVerilog

// Top-level 8-bit Adder using Hierarchical Manchester Carry Chain
module adder_8bit_manchester_hier (
  input [7:0] a,      // First operand
  input [7:0] b,      // Second operand
  input       cin,    // Carry-in
  output[7:0] sum,    // Sum output
  output      cout    // Carry-out
);

  // Internal wires connecting submodules
  wire [7:0]  w_g;        // Generate signals from GP unit
  wire [7:0]  w_p;        // Propagate signals from GP unit
  wire [8:0]  w_c_chain;  // Carry signals from Carry Chain unit (c[0] is cin, c[8] is cout)

  // Instantiate Generate and Propagate calculation unit
  generate_propagate_unit_8bit u_gp_unit (
    .a_in (a),
    .b_in (b),
    .g_out(w_g),
    .p_out(w_p)
  );

  // Instantiate Manchester Carry Chain unit
  manchester_carry_chain_8bit u_carry_chain (
    .g_in     (w_g),
    .p_in     (w_p),
    .cin      (cin),
    .c_chain_out(w_c_chain)
  );

  // Instantiate Sum calculation unit
  sum_unit_8bit u_sum_unit (
    .p_in   (w_p),
    .c_in   (w_c_chain[7:0]), // Use intermediate carries for sum calculation
    .sum_out(sum)
  );

  // Assign final carry-out from the chain
  assign cout = w_c_chain[8];

endmodule

// Submodule: Calculates Generate (g) and Propagate (p) signals for 8 bits
module generate_propagate_unit_8bit (
  input [7:0] a_in, // Input operand A
  input [7:0] b_in, // Input operand B
  output[7:0] g_out,// Output Generate signals (a_in & b_in)
  output[7:0] p_out // Output Propagate signals (a_in ^ b_in)
);

  assign g_out = a_in & b_in;
  assign p_out = a_in ^ b_in;

endmodule

// Submodule: Implements the 8-bit Manchester Carry Chain logic
module manchester_carry_chain_8bit (
  input [7:0] g_in,     // Input Generate signals
  input [7:0] p_in,     // Input Propagate signals
  input       cin,      // Input Carry-in
  output[8:0] c_chain_out // Output Carry chain signals (c[0]=cin, c[1..7]=intermediate, c[8]=cout)
);

  // Wires for internal carry chain
  wire [8:0] c;

  // Assign input carry
  assign c[0] = cin;

  // Implement carry chain logic: c[i+1] = g[i] | (p[i] & c[i])
  // This structure forms the critical path of the adder
  assign c[1] = g_in[0] | (p_in[0] & c[0]);
  assign c[2] = g_in[1] | (p_in[1] & c[1]);
  assign c[3] = g_in[2] | (p_in[2] & c[2]);
  assign c[4] = g_in[3] | (p_in[3] & c[4]);
  assign c[5] = g_in[4] | (p_in[4] & c[5]);
  assign c[6] = g_in[5] | (p_in[5] & c[6]);
  assign c[7] = g_in[6] | (p_in[6] & c[7]);
  assign c[8] = g_in[7] | (p_in[7] & c[7]);

  // Assign output carry chain
  assign c_chain_out = c;

endmodule

// Submodule: Calculates the 8-bit sum
module sum_unit_8bit (
  input [7:0] p_in,   // Input Propagate signals
  input [7:0] c_in,   // Input Carry signals (intermediate carries c[0]..c[7])
  output[7:0] sum_out // Output Sum signals (p_in ^ c_in)
);

  // Calculate sum bits: sum[i] = p[i] ^ c[i]
  assign sum_out = p_in ^ c_in;

endmodule