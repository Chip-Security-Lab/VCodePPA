//SystemVerilog
// Top level module for the 4-bit Kogge-Stone adder
// Refactored into functional sub-modules for improved structure and maintainability
module adder_11 (
  input [3:0] a,
  input [3:0] b,
  output [4:0] sum
);

  // Internal wires connecting sub-modules
  wire [3:0] w_gen_initial;  // Initial generate signals
  wire [3:0] w_prop_initial; // Initial propagate signals
  wire [3:0] w_gen_L2;       // Generate signals from final prefix layer
  wire [3:0] w_prop_L2;      // Propagate signals from final prefix layer
  wire [3:0] w_carries;      // Carry-in to each bit position
  wire       w_carry_out;    // Carry out of the most significant bit

  // Instantiate sub-modules

  // 1. Generate initial G and P signals from inputs a and b
  gp_generator u_gp_gen (
    .a_in    (a),
    .b_in    (b),
    .gen_out (w_gen_initial),
    .prop_out(w_prop_initial)
  );

  // 2. Compute prefix G and P signals using the Kogge-Stone network structure
  // This module implements the layered black/white cell logic
  kogge_stone_prefix_network u_prefix_net (
    .gen_in    (w_gen_initial),
    .prop_in   (w_prop_initial),
    .gen_L2_out(w_gen_L2),
    .prop_L2_out(w_prop_L2) // Propagate signals are not strictly needed for carries but kept for completeness
  );

  // 3. Generate carries for each bit position based on the final prefix G signals
  // The carries are derived from the results of the prefix network
  carry_generator u_carry_gen (
    .gen_L2_in  (w_gen_L2),      // Final generate signals from prefix network
    .carries_out(w_carries),     // Carry into each bit (carries_out[i] is C[i-1])
    .carry_out  (w_carry_out)    // Carry out of the MSB (C[3])
  );

  // 4. Compute the final sum bits using initial propagate signals and carries
  sum_generator u_sum_gen (
    .prop_in    (w_prop_initial),// Initial propagate signals
    .carries_in (w_carries),     // Carry into each bit position
    .carry_out_in(w_carry_out),  // Carry out of the MSB
    .sum_out    (sum)            // Final sum including carry out
  );

endmodule

// Sub-module: Generates initial Generate (a&b) and Propagate (a^b) signals for each bit
module gp_generator (
  input [3:0] a_in,
  input [3:0] b_in,
  output [3:0] gen_out,  // a_in[i] & b_in[i]
  output [3:0] prop_out  // a_in[i] ^ b_in[i]
);

  assign gen_out  = a_in & b_in;
  assign prop_out = a_in ^ b_in;

endmodule

// Sub-module: Implements the Kogge-Stone prefix network for a 4-bit adder
// Computes the prefix G and P signals across two layers (log2(4) = 2)
module kogge_stone_prefix_network (
  input [3:0] gen_in,     // Initial generate signals (G[i][0])
  input [3:0] prop_in,    // Initial propagate signals (P[i][0])
  output [3:0] gen_L2_out, // Generate signals from the final layer (G[i][2])
  output [3:0] prop_L2_out// Propagate signals from the final layer (P[i][2])
);

  // Internal signals for Layer 1 G/P (distance 2^0 = 1)
  wire [3:0] gen_L1;
  wire [3:0] prop_L1;

  // Layer 1 computation (distance 1) using black and white cells
  // G[i][1] = G[i][0] | (P[i][0] & G[i-1][0])
  // P[i][1] = P[i][0] & P[i-1][0]
  // White cells (i=0): G[0][1]=G[0][0], P[0][1]=P[0][0]
  // Black cells (i>0): Apply the recurrence
  assign gen_L1[0] = gen_in[0];
  assign prop_L1[0] = prop_in[0];
  assign gen_L1[1] = gen_in[1] | (prop_in[1] & gen_in[0]);
  assign prop_L1[1] = prop_in[1] & prop_in[0];
  assign gen_L1[2] = gen_in[2] | (prop_in[2] & gen_in[1]);
  assign prop_L1[2] = prop_in[2] & prop_in[1];
  assign gen_L1[3] = gen_in[3] | (prop_in[3] & gen_in[2]);
  assign prop_L1[3] = prop_in[3] & prop_in[2];

  // Internal signals for Layer 2 G/P (distance 2^1 = 2)
  wire [3:0] gen_L2;
  wire [3:0] prop_L2;

  // Layer 2 computation (distance 2) using black and white cells
  // G[i][2] = G[i][1] | (P[i][1] & G[i-2][1])
  // P[i][2] = P[i][1] & P[i-2][1]
  // White cells (i=0,1): G[i][2]=G[i][1], P[i][2]=P[i][1]
  // Black cells (i>1): Apply the recurrence (G[i-2][1] and P[i-2][1] are needed)
  assign gen_L2[0] = gen_L1[0];
  assign prop_L2[0] = prop_L1[0];
  assign gen_L2[1] = gen_L1[1];
  assign prop_L2[1] = prop_L1[1];
  assign gen_L2[2] = gen_L1[2] | (prop_L1[2] & gen_L1[0]); // Uses G[0][1]
  assign prop_L2[2] = prop_L1[2] & prop_L1[0];           // Uses P[0][1]
  assign gen_L2[3] = gen_L1[3] | (prop_L1[3] & gen_L1[1]); // Uses G[1][1]
  assign prop_L2[3] = prop_L1[3] & prop_L1[1];           // Uses P[1][1]

  // Output the final layer results (G[i][2] and P[i][2])
  assign gen_L2_out  = gen_L2;
  assign prop_L2_out = prop_L2;

endmodule

// Sub-module: Generates the carry-in for each bit position and the final carry-out
// Based on the final generate signals from the prefix network
module carry_generator (
  input [3:0] gen_L2_in,     // Generate signals from the final prefix layer (G[i][2])
  output [3:0] carries_out,  // Carry into bit i (carries_out[i] is C[i-1])
  output       carry_out     // Carry out of the MSB (C[3])
);

  // The carry into bit i (C[i-1]) is equal to G[i-1][log2(N)] when carry_in=0.
  // For N=4, log2(N)=2. C[i-1] = G[i-1][2].
  // carries_out[0] = C[-1] = carry_in = 0 (for simple addition)
  // carries_out[1] = C[0] = G[0][2]
  // carries_out[2] = C[1] = G[1][2]
  // carries_out[3] = C[2] = G[2][2]
  assign carries_out[0] = 1'b0; // Carry into bit 0 is always 0 for a+b
  assign carries_out[1] = gen_L2_in[0];
  assign carries_out[2] = gen_L2_in[1];
  assign carries_out[3] = gen_L2_in[2];

  // The carry out of the MSB (C[3]) is G[3][2]
  assign carry_out = gen_L2_in[3];

endmodule

// Sub-module: Generates the final sum bits
// Sum[i] = Propagate[i] ^ Carry_in[i]
module sum_generator (
  input [3:0] prop_in,     // Initial Propagate signals (a[i] ^ b[i])
  input [3:0] carries_in,  // Carry into each bit position (C[i-1])
  input       carry_out_in,// Carry out of the MSB (C[3])
  output [4:0] sum_out     // Final sum output (sum[0:3] are bit sums, sum[4] is final carry out)
);

  // Compute sum bits 0 through 3
  // sum[i] = prop_in[i] ^ carries_in[i]
  assign sum_out[0] = prop_in[0] ^ carries_in[0]; // carries_in[0] is 0, so sum_out[0] = prop_in[0]
  assign sum_out[1] = prop_in[1] ^ carries_in[1];
  assign sum_out[2] = prop_in[2] ^ carries_in[2];
  assign sum_out[3] = prop_in[3] ^ carries_in[3];

  // The most significant bit of the sum is the final carry out
  assign sum_out[4] = carry_out_in;

endmodule