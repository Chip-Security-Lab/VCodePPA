//SystemVerilog
module proc_adder(
  input [5:0] p, q,
  output [6:0] result
);

  // Signals for generate and propagate
  wire [5:0] generate_sig;
  wire [5:0] propagate_sig;

  // Calculate generate and propagate for each bit
  genvar i;
  generate
    for (i = 0; i <= 5; i = i + 1) begin : gen_prop_loop
      assign generate_sig[i] = p[i] & q[i];
      assign propagate_sig[i] = p[i] ^ q[i];
    end
  endgenerate

  // Signals for carries
  // carry_in_to_bit[i] is the carry into bit i.
  // carry_in_to_bit[6] is the carry out of bit 5.
  wire [6:0] carry_in_to_bit;

  // Input carry to bit 0 is 0 for simple addition
  assign carry_in_to_bit[0] = 1'b0;

  // --- Carry Skip Adder Logic (3 groups of 2 bits) ---
  // Group 0: bits 0, 1
  // Group 1: bits 2, 3
  // Group 2: bits 4, 5

  // Group 0 (bits 0, 1) Skip Logic
  wire group0_propagate_all = propagate_sig[0] & propagate_sig[1];
  wire group0_generate_overall = generate_sig[1] | (propagate_sig[1] & generate_sig[0]);
  wire carry_out_group0_skip = group0_generate_overall | (group0_propagate_all & carry_in_to_bit[0]); // Carry out of Group 0 (Skip)

  // Group 1 (bits 2, 3) Skip Logic
  wire group1_propagate_all = propagate_sig[2] & propagate_sig[3];
  wire group1_generate_overall = generate_sig[3] | (propagate_sig[3] & generate_sig[2]);
  wire carry_out_group1_skip = group1_generate_overall | (group1_propagate_all & carry_out_group0_skip); // Carry out of Group 1 (Skip)

  // Group 2 (bits 4, 5) Skip Logic
  wire group2_propagate_all = propagate_sig[4] & propagate_sig[5];
  wire group2_generate_overall = generate_sig[5] | (propagate_sig[5] & generate_sig[4]);
  wire carry_out_group2_skip = group2_generate_overall | (group2_propagate_all & carry_out_group1_skip); // Carry out of Group 2 (Skip)

  // Calculate individual bit carries using a combination of ripple and skip paths
  // Carries within Group 0 (ripple from carry_in_to_bit[0])
  assign carry_in_to_bit[1] = generate_sig[0] | (propagate_sig[0] & carry_in_to_bit[0]);

  // Carry into Group 1 (bit 2) is the skip carry out of Group 0
  assign carry_in_to_bit[2] = carry_out_group0_skip;

  // Carries within Group 1 (ripple from carry_in_to_bit[2])
  assign carry_in_to_bit[3] = generate_sig[2] | (propagate_sig[2] & carry_in_to_bit[2]);

  // Carry into Group 2 (bit 4) is the skip carry out of Group 1
  assign carry_in_to_bit[4] = carry_out_group1_skip;

  // Carries within Group 2 (ripple from carry_in_to_bit[4])
  assign carry_in_to_bit[5] = generate_sig[4] | (propagate_sig[4] & carry_in_to_bit[4]);

  // Carry out of bit 5 (Carry into bit 6) is the ripple carry out of the last bit in Group 2
  assign carry_in_to_bit[6] = generate_sig[5] | (propagate_sig[5] & carry_in_to_bit[5]); // This is the final carry out

  // Calculate sum bits
  wire [5:0] sum_bits;
  generate
    for (i = 0; i <= 5; i = i + 1) begin : sum_loop
      assign sum_bits[i] = propagate_sig[i] ^ carry_in_to_bit[i];
    end
  endgenerate

  // Combine final carry and sum bits for the 7-bit result
  assign result = {carry_in_to_bit[6], sum_bits};

endmodule