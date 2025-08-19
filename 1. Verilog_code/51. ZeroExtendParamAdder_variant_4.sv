//SystemVerilog
module cat_add (
  input [7:0] in1, in2,
  output [8:0] out
);

  localparam N = 8;

  // Wires for propagate and generate signals
  wire [N-1:0] p, g;

  // Wires for intermediate propagate and generate signals in the prefix tree
  wire [N-1:0] p1, g1; // Level 1 (distance 1)
  wire [N-1:0] p2, g2; // Level 2 (distance 2)
  wire [N-1:0] p3, g3; // Level 3 (distance 4)

  // Wires for carries (c[i] is carry *into* bit i)
  wire [N:0] c; // c[0] is carry-in, c[N] is carry-out

  // Wires for sum bits
  wire [N-1:0] s;

  // Level 0: Initial propagate and generate
  assign p = in1 ^ in2;
  assign g = in1 & in2;

  // Kogge-Stone Prefix Tree
  // Level 1 (distance 1)
  assign g1[0] = g[0];
  assign p1[0] = p[0];
  generate
    genvar i;
    for (i = 1; i < N; i = i + 1) begin : gen_level1
      assign g1[i] = g[i] | (p[i] & g[i-1]);
      assign p1[i] = p[i] & p[i-1];
    end
  endgenerate

  // Level 2 (distance 2)
  assign g2[0] = g1[0];
  assign p2[0] = p1[0];
  assign g2[1] = g1[1];
  assign p2[1] = p1[1];
  generate
    genvar j;
    for (j = 2; j < N; j = j + 1) begin : gen_level2
      assign g2[j] = g1[j] | (p1[j] & g1[j-2]);
      assign p2[j] = p1[j] & p1[j-2];
    end
  endgenerate

  // Level 3 (distance 4)
  assign g3[0] = g2[0];
  assign p3[0] = p2[0];
  assign g3[1] = g2[1];
  assign p3[1] = p2[1];
  assign g3[2] = g2[2];
  assign p3[2] = p2[2];
  assign g3[3] = g2[3];
  assign p3[3] = p2[3];
  generate
    genvar k;
    for (k = 4; k < N; k = k + 1) begin : gen_level3
      assign g3[k] = g2[k] | (p2[k] & g2[k-4]);
      assign p3[k] = p2[k] & p2[k-4];
    end
  endgenerate

  // Carries (c[i] is carry *into* bit i)
  // c[i] = G_final[i-1] where G_final[k] is generate for range [0:k]
  // G_final[k] = g_level_X[k] | (p_level_X[k] & G_final[k - 2^X]) for k >= 2^X
  // G_final[k] = g_level_Y[k] for 2^Y <= k < 2^(Y+1)

  assign c[0] = 1'b0; // Carry-in

  // G_final[0] = g[0]
  assign c[1] = g[0];

  // G_final[1] = g1[1]
  assign c[2] = g1[1];

  // G_final[2] = g2[2]
  assign c[3] = g2[2];

  // G_final[3] = g2[3]
  assign c[4] = g2[3];

  // G_final[4] = g3[4] | (p3[4] & G_final[0]) = g3[4] | (p3[4] & g[0])
  assign c[5] = g3[4] | (p3[4] & g[0]);

  // G_final[5] = g3[5] | (p3[5] & G_final[1]) = g3[5] | (p3[5] & g1[1])
  assign c[6] = g3[5] | (p3[5] & g1[1]);

  // G_final[6] = g3[6] | (p3[6] & G_final[2]) = g3[6] | (p3[6] & g2[2])
  assign c[7] = g3[6] | (p3[6] & g2[2]);

  // G_final[7] = g3[7] | (p3[7] & G_final[3]) = g3[7] | (p3[7] & g2[3])
  assign c[8] = g3[7] | (p3[7] & g2[3]); // Carry out of bit 7 (Overall Carry-Out)


  // Sum bits
  generate
    genvar l;
    for (l = 0; l < N; l = l + 1) begin : gen_sum
      assign s[l] = p[l] ^ c[l]; // Sum[i] = P[i] ^ Carry_in_to_bit_i
    end
  endgenerate

  // Output
  assign out = {c[N], s}; // {Carry-out, Sum[N-1:0]}

endmodule