//SystemVerilog
// full_adder_1bit module
// Implements a standard 1-bit full adder
module full_adder_1bit (
    input logic a_i,    // First input bit
    input logic b_i,    // Second input bit
    input logic cin_i,  // Carry input bit
    output logic sum_o, // Sum output bit
    output logic cout_o // Carry output bit
);

  // Standard full adder logic
  assign sum_o = a_i ^ b_i ^ cin_i;
  assign cout_o = (a_i & b_i) | (cin_i & (a_i ^ b_i));

endmodule

// adder_8 module (Top level)
// Implements an 8-bit ripple-carry adder using 1-bit full adders
module adder_8 (
    input logic [7:0] a_i,   // First 8-bit input
    input logic [7:0] b_i,   // Second 8-bit input
    input logic       cin_i, // Carry input for the LSB
    output logic [7:0] sum_o, // 8-bit sum output
    output logic      cout_o // Carry output from the MSB
);

  // Internal carry signals for the ripple-carry chain
  // carry_chain[i] holds the carry out of the full_adder_1bit at stage i
  logic [7:0] carry_chain;

  // Instantiate 8 full_adder_1bit modules
  // Stage 0 (LSB): Connects to cin_i
  full_adder_1bit fa_0 (
      .a_i(a_i[0]),
      .b_i(b_i[0]),
      .cin_i(cin_i),          // Input carry for stage 0 comes from top-level cin_i
      .sum_o(sum_o[0]),
      .cout_o(carry_chain[0]) // Output carry of stage 0 feeds stage 1
  );

  // Stages 1 to 7 (MSB): Connects carry_chain[i-1] to cin_i
  generate
    for (genvar i = 1; i <= 7; i++) begin : fa_gen
      full_adder_1bit fa_inst (
          .a_i(a_i[i]),
          .b_i(b_i[i]),
          .cin_i(carry_chain[i-1]), // Input carry for stage i comes from output carry of stage i-1
          .sum_o(sum_o[i]),
          .cout_o(carry_chain[i])   // Output carry of stage i feeds stage i+1 (or cout_o for stage 7)
      );
    end
  endgenerate

  // The final carry out of the MSB adder (stage 7) is the top-level cout_o
  assign cout_o = carry_chain[7];

endmodule