//SystemVerilog
// SystemVerilog
// Refactored 6-bit Parallel Prefix Adder
// Structure organized into distinct stages for clarity of data flow.
// This is a combinational implementation.
module proc_adder(
  input [5:0] p, q,
  output [6:0] result
);

  //----------------------------------------------------------------------------
  // Stage 0: Initial Generate and Propagate (G[i:i], P[i:i])
  // g_i = p_i & q_i (Generate a carry)
  // p_i = p_i ^ q_i (Propagate a carry)
  //----------------------------------------------------------------------------
  wire [5:0] stage0_gen;  // G[i:i] for bit i
  wire [5:0] stage0_prop; // P[i:i] for bit i

  assign stage0_gen  = p & q;
  assign stage0_prop = p ^ q;

  //----------------------------------------------------------------------------
  // Prefix Network Stages
  // Computes block Generate (G[i:j]) and Propagate (P[i:j]) signals
  // using the parallel prefix operation:
  // (G[i:j], P[i:j]) = (G[k+1:j], P[k+1:j]) o (G[i:k], P[i:k])
  // where (G_R, P_R) o (G_L, P_L) = (G_R | (P_R & G_L), P_R & P_L)
  // The specific connections follow the structure of the original adder.
  //----------------------------------------------------------------------------

  // Stage 1: Combine adjacent bits (block size 2)
  // Computes (G[i:i+1], P[i:i+1]) for i = 0, 2, 4
  wire [5:0] stage1_gen;  // G[i:i+1] results stored at index i+1
  wire [5:0] stage1_prop; // P[i:i+1] results stored at index i+1

  // Combine bits 0 and 1 -> G[0:1], P[0:1]
  assign stage1_gen[1]  = stage0_gen[1]  | (stage0_prop[1] & stage0_gen[0]);
  assign stage1_prop[1] = stage0_prop[1] & stage0_prop[0];

  // Combine bits 2 and 3 -> G[2:3], P[2:3]
  assign stage1_gen[3]  = stage0_gen[3]  | (stage0_prop[3] & stage0_gen[2]);
  assign stage1_prop[3] = stage0_prop[3] & stage0_prop[2];

  // Combine bits 4 and 5 -> G[4:5], P[4:5]
  assign stage1_gen[5]  = stage0_gen[5]  | (stage0_prop[5] & stage0_gen[4]);
  assign stage1_prop[5] = stage0_prop[5] & stage0_prop[4];


  // Stage 2: Combine 2-bit blocks (block size 4)
  // Computes (G[0:3], P[0:3])
  wire [5:0] stage2_gen;  // G[0:3] result stored at index 3
  wire [5:0] stage2_prop; // P[0:3] result stored at index 3

  // Combine block [2:3] and [0:1] -> G[0:3], P[0:3]
  assign stage2_gen[3]  = stage1_gen[3]  | (stage1_prop[3] & stage1_gen[1]);
  assign stage2_prop[3] = stage1_prop[3] & stage1_prop[1];


  // Stage 3: Combine blocks (block size 6)
  // Computes (G[0:5], P[0:5])
  wire [5:0] stage3_gen;  // G[0:5] result stored at index 5
  wire [5:0] stage3_prop; // P[0:5] result stored at index 5

  // Combine block [4:5] and [0:3] -> G[0:5], P[0:5]
  assign stage3_gen[5]  = stage1_gen[5]  | (stage1_prop[5] & stage2_gen[3]);
  assign stage3_prop[5] = stage1_prop[5] & stage2_prop[3];


  //----------------------------------------------------------------------------
  // Carry Generation (c_i = carry into bit i)
  // c_i = G[0:i-1] | (P[0:i-1] & c_in)
  // For this adder, c_in (carry into bit 0) is 0.
  // c_i = G[0:i-1]
  //----------------------------------------------------------------------------
  wire [6:0] carry_in; // carry_in[i] is the carry into bit i

  assign carry_in[0] = 1'b0; // Explicitly show carry-in is 0

  // Derive carries from prefix network outputs
  // c1 = G[0:0]
  assign carry_in[1] = stage0_gen[0];

  // c2 = G[0:1]
  assign carry_in[2] = stage1_gen[1];

  // c3 = G[0:2] = G[2:2] | (P[2:2] & G[0:1])
  assign carry_in[3] = stage0_gen[2] | (stage0_prop[2] & stage1_gen[1]);

  // c4 = G[0:3]
  assign carry_in[4] = stage2_gen[3];

  // c5 = G[0:4] = G[4:4] | (P[4:4] & G[0:3])
  assign carry_in[5] = stage0_gen[4] | (stage0_prop[4] & stage2_gen[3]);

  // c6 = G[0:5] (Final carry out)
  assign carry_in[6] = stage3_gen[5];


  //----------------------------------------------------------------------------
  // Sum Generation
  // sum_i = p_i ^ q_i ^ c_i = P[i:i] ^ c_i
  //----------------------------------------------------------------------------
  wire [5:0] sum_bits;

  // Sum for each bit position
  assign sum_bits = stage0_prop ^ carry_in[5:0]; // XOR p_i^q_i with carry_i

  //----------------------------------------------------------------------------
  // Final Result
  // Concatenate sum bits and the final carry out.
  //----------------------------------------------------------------------------
  assign result[5:0] = sum_bits;
  assign result[6]   = carry_in[6]; // The carry-out of the MSB is result[6]

endmodule