//SystemVerilog
// Submodule: Generates propagate and generate signals for a 4-bit input
module pg_generator (
  input [3:0] a,
  input [3:0] b,
  output [3:0] propagate,
  output [3:0] generate_bit
);
  assign propagate = a ^ b;
  assign generate_bit = a & b;
endmodule

// Submodule: Calculates carry-out for a single bit position
// Implements c_out = g_in | (p_in & c_in)
module carry_stage (
  input p_in,
  input g_in,
  input c_in,
  output c_out
);
  assign c_out = g_in | (p_in & c_in);
endmodule

// Submodule: Generates the sum bits (excluding carry-out)
// Implements sum_bit[i] = propagate[i] ^ carry_in[i]
module sum_generator (
  input [3:0] propagate,
  input [3:0] carry_in_bits, // carry[0] through carry[3] from the chain
  output [3:0] sum_bits
);
  assign sum_bits = propagate ^ carry_in_bits;
endmodule

// Top module: Hierarchical 4-bit adder using PG, Carry Chain, and Sum submodules
module adder_4bit_hierarchical (
  input [3:0] a,
  input [3:0] b,
  output [4:0] sum
);

  // Internal wires for intermediate signals
  wire [3:0] propagate_w;
  wire [3:0] generate_bit_w;
  // carry_w[i] is the carry-in to bit i, carry_w[i+1] is the carry-out of bit i
  wire [4:0] carry_w;
  wire [3:0] sum_bits_w; // sum[0]..[3]

  // Connect overall carry-in (Cin) to the first stage
  assign carry_w[0] = 1'b0; // Assuming no carry-in for a simple adder

  // Instantiate PG Generator submodule
  pg_generator u_pg_gen (
    .a(a),
    .b(b),
    .propagate(propagate_w),
    .generate_bit(generate_bit_w)
  );

  // Instantiate Carry Chain stages
  // Each stage calculates carry_w[i+1] from carry_w[i], propagate_w[i], and generate_bit_w[i]
  carry_stage u_carry_stage_0 (
    .p_in(propagate_w[0]),
    .g_in(generate_bit_w[0]),
    .c_in(carry_w[0]),
    .c_out(carry_w[1])
  );

  carry_stage u_carry_stage_1 (
    .p_in(propagate_w[1]),
    .g_in(generate_bit_w[1]),
    .c_in(carry_w[1]),
    .c_out(carry_w[2])
  );

  carry_stage u_carry_stage_2 (
    .p_in(propagate_w[2]),
    .g_in(generate_bit_w[2]),
    .c_in(carry_w[2]),
    .c_out(carry_w[3])
  );

  carry_stage u_carry_stage_3 (
    .p_in(propagate_w[3]),
    .g_in(generate_bit_w[3]),
    .c_in(carry_w[3]),
    .c_out(carry_w[4]) // Final carry-out
  );

  // Instantiate Sum Generator submodule
  // Needs propagate bits and the carry-in to each bit position (carry_w[0]..carry_w[3])
  sum_generator u_sum_gen (
    .propagate(propagate_w),
    .carry_in_bits(carry_w[3:0]), // Pass carry_w[0] for bit 0, carry_w[1] for bit 1, etc.
    .sum_bits(sum_bits_w)
  );

  // Connect sum outputs
  assign sum[3:0] = sum_bits_w;
  assign sum[4] = carry_w[4]; // MSB of sum is the final carry-out

endmodule