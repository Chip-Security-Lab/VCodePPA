//SystemVerilog
module adder_13 (
  input clk,
  input reset,
  input [7:0] a,
  input [7:0] b,
  input cin,
  output [7:0] sum,
  output cout
);

  // Internal signals for generate (g) and propagate (p)
  wire [7:0] p, g;

  // Internal signals for prefix tree outputs (G, P) at different levels
  // G_Lx[i], P_Lx[i] represent the generate/propagate for a span ending at bit i
  wire [7:0] G_L1, P_L1; // Level 1: Span 2
  wire [7:0] G_L2, P_L2; // Level 2: Span 4
  wire [7:0] G_L3, P_L3; // Level 3: Span 8

  // Internal signals for carries
  // c[i] is the carry *into* bit i. c[0] is cin, c[8] is cout.
  wire [8:0] c;

  // Combinatorial sum output before registration
  wire [7:0] sum_comb;

  // Registered outputs
  reg [7:0] sum_reg;
  reg cout_reg;

  // Level 0: Pre-processing (Generate and Propagate for each bit)
  assign p = a ^ b;
  assign g = a & b;

  // Level 1: Span 2 (Pairs) - Black Cells
  // (G_1:0, P_1:0)
  assign {G_L1[1], P_L1[1]} = {g[1] | (p[1] & g[0]), p[1] & p[0]};
  // (G_3:2, P_3:2)
  assign {G_L1[3], P_L1[3]} = {g[3] | (p[3] & g[2]), p[3] & p[2]};
  // (G_5:4, P_5:4)
  assign {G_L1[5], P_L1[5]} = {g[5] | (p[5] & g[4]), p[5] & p[4]};
  // (G_7:6, P_7:6)
  assign {G_L1[7], P_L1[7]} = {g[7] | (p[7] & g[6]), p[7] & p[6]};

  // Level 2: Span 4 (Quads) - Sparse Black Cells for Han-Carlson
  // (G_3:0, P_3:0) from (G_3:2, P_3:2) and (G_1:0, P_1:0)
  assign {G_L2[3], P_L2[3]} = {G_L1[3] | (P_L1[3] & G_L1[1]), P_L1[3] & P_L1[1]};
  // (G_7:4, P_7:4) from (G_7:6, P_7:6) and (G_5:4, P_5:4)
  assign {G_L2[7], P_L2[7]} = {G_L1[7] | (P_L1[7] & G_L1[5]), P_L1[7] & P_L1[5]};

  // Level 3: Span 8 (Octets) - Sparse Black Cell for Han-Carlson
  // (G_7:0, P_7:0) from (G_7:4, P_7:4) and (G_3:0, P_3:0)
  assign {G_L3[7], P_L3[7]} = {G_L2[7] | (P_L2[7] & G_L2[3]), P_L2[7] & P_L2[3]};

  // Carry Generation (using Gray Cells and Black Cells outputs)
  // c[i] = G[i-1:0] + P[i-1:0] * c[0] (simplified view)
  // Han-Carlson computes carries using sparse connections
  assign c[0] = cin;                         // Carry into bit 0 is input carry
  assign c[1] = g[0] | (p[0] & c[0]);        // Carry into bit 1
  assign c[2] = G_L1[1] | (P_L1[1] & c[0]);  // Carry into bit 2 (from G[1:0], P[1:0] and cin)
  assign c[3] = g[2] | (p[2] & c[2]);        // Carry into bit 3
  assign c[4] = G_L2[3] | (P_L2[3] & c[0]);  // Carry into bit 4 (from G[3:0], P[3:0] and cin)
  assign c[5] = g[4] | (p[4] & c[4]);        // Carry into bit 5
  assign c[6] = G_L1[5] | (P_L1[5] & c[4]);  // Carry into bit 6 (from G[5:4], P[5:4] and c[4])
  assign c[7] = g[6] | (p[6] & c[6]);        // Carry into bit 7
  assign c[8] = G_L3[7] | (P_L3[7] & c[0]);  // Carry out (from G[7:0], P[7:0] and cin)

  // Post-processing: Sum calculation
  // sum[i] = p[i] ^ c[i]
  assign sum_comb = p ^ c[7:0];

  // Registered Output
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      sum_reg <= 8'b0;
      cout_reg <= 1'b0;
    end else begin
      sum_reg <= sum_comb;
      cout_reg <= c[8];
    end
  end

  // Assign registered outputs to module outputs
  assign sum = sum_reg;
  assign cout = cout_reg;

endmodule