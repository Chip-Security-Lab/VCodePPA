//SystemVerilog
// Top-level module for the hierarchical 8-bit adder
module adder_8bit_hierarchical (
  input wire [7:0] a,
  input wire [7:0] b,
  output wire [7:0] sum
);

  // Internal wires connecting submodules
  wire [7:0] prop_w; // Propagate signals from GP generator
  wire [7:0] gen_w;  // Generate signals from GP generator
  wire [7:0] carries_for_sum_w; // Carry-in signals for each bit of sum from Carry Chain
  wire cin_w = 1'b0; // Initial carry-in, tied to 0 as in the original

  // Instantiate the Generate and Propagate signal generator
  gp_generator_8bit gp_gen_inst (
    .a_in    (a),
    .b_in    (b),
    .gen_out (gen_w),
    .prop_out(prop_w)
  );

  // Instantiate the Manchester Carry Chain
  carry_chain_8bit carry_chain_inst (
    .gen_in           (gen_w),
    .prop_in          (prop_w),
    .cin_in           (cin_w),
    .carries_for_sum_out(carries_for_sum_w)
  );

  // Instantiate the Sum calculator
  sum_calculator_8bit sum_calc_inst (
    .prop_in     (prop_w),
    .carries_in  (carries_for_sum_w),
    .sum_out     (sum)
  );

endmodule

// Submodule to generate Propagate and Generate signals for each bit
// Function: P_i = a_i ^ b_i, G_i = a_i & b_i
module gp_generator_8bit (
  input wire [7:0] a_in,
  input wire [7:0] b_in,
  output wire [7:0] gen_out,  // Generate signals
  output wire [7:0] prop_out // Propagate signals
);

  // Calculate P_i and G_i for each bit
  assign prop_out = a_in ^ b_in;
  assign gen_out  = a_in & b_in;

endmodule

// Submodule to calculate the Manchester Carry Chain
// This module calculates the carry-in for each bit position of the sum (C_i)
// using the carry propagation formula: C_i = G_{i-1} | (P_{i-1} & C_{i-1})
module carry_chain_8bit (
  input wire [7:0] gen_in,  // Generate signals (G_i)
  input wire [7:0] prop_in, // Propagate signals (P_i)
  input wire       cin_in,  // Initial carry-in (C_0)
  output wire [7:0] carries_for_sum_out // Carry-in for sum calculation at each bit (C_i)
);

  // Internal wires for carry propagation (carry_out from bit i, which is carry_in to bit i+1)
  wire [7:0] carry_out_from_bit;

  // Calculate carry_out_from_bit[i] = gen_in[i] | (prop_in[i] & carry_in_to_bit_i)
  // carry_in_to_bit_i is cin_in for i=0, and carry_out_from_bit[i-1] for i>0
  assign carry_out_from_bit[0] = gen_in[0] | (prop_in[0] & cin_in);
  assign carry_out_from_bit[1] = gen_in[1] | (prop_in[1] & carry_out_from_bit[0]);
  assign carry_out_from_bit[2] = gen_in[2] | (prop_in[2] & carry_out_from_bit[1]);
  assign carry_out_from_bit[3] = gen_in[3] | (prop_in[3] & carry_out_from_bit[2]);
  assign carry_out_from_bit[4] = gen_in[4] | (prop_in[4] & carry_out_from_bit[3]);
  assign carry_out_from_bit[5] = gen_in[5] | (prop_in[5] & carry_out_from_bit[4]);
  assign carry_out_from_bit[6] = gen_in[6] | (prop_in[6] & carry_out_from_bit[5]);
  assign carry_out_from_bit[7] = gen_in[7] | (prop_in[7] & carry_out_from_bit[6]);

  // The carry-in for sum[i] is the carry_out_from_bit[i-1] for i>0, and cin_in for i=0
  assign carries_for_sum_out[0] = cin_in;
  assign carries_for_sum_out[1] = carry_out_from_bit[0];
  assign carries_for_sum_out[2] = carry_out_from_bit[1];
  assign carries_for_sum_out[3] = carry_out_from_bit[2];
  assign carries_for_sum_out[4] = carry_out_from_bit[3];
  assign carries_for_sum_out[5] = carry_out_from_bit[4];
  assign carries_for_sum_out[6] = carry_out_from_bit[5];
  assign carries_for_sum_out[7] = carry_out_from_bit[6];

endmodule

// Submodule to calculate the Sum based on Propagate and Carry-in signals
// Function: S_i = P_i ^ C_i
module sum_calculator_8bit (
  input wire [7:0] prop_in,    // Propagate signals (P_i)
  input wire [7:0] carries_in, // Carry-in for each bit (C_i)
  output wire [7:0] sum_out    // Sum output (S_i)
);

  // Calculate Sum_i = P_i ^ C_i for each bit
  assign sum_out = prop_in ^ carries_in;

endmodule