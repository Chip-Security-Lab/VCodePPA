//SystemVerilog
module adder_14 (input [3:0] a, input [3:0] b, output [4:0] sum);

  // 1. Generate and Propagate (Bit-level)
  wire [3:0] p;
  wire [3:0] g;
  assign p = a ^ b;
  assign g = a & b;

  // 2. Parallel Prefix Tree (Kogge-Stone N=4)
  // Level 1 (Distance 1)
  wire [3:0] p1, g1;
  assign g1[0] = g[0];
  assign p1[0] = p[0];
  assign g1[1] = g[1] | (p[1] & g[0]);
  assign p1[1] = p[1] & p[0];
  assign g1[2] = g[2] | (p[2] & g[1]);
  assign p1[2] = p[2] & p[1];
  assign g1[3] = g[3] | (p[3] & g[2]);
  assign p1[3] = p[3] & p[2];

  // Level 2 (Distance 2)
  wire [3:0] g2;
  assign g2[2] = g1[2] | (p1[2] & g1[0]);
  assign g2[3] = g1[3] | (p1[3] & g1[1]);

  // 3. Compute Carries (c[i] is carry *into* bit i)
  wire [4:0] c;
  assign c[0] = 1'b0;
  assign c[1] = g[0];
  assign c[2] = g1[1];
  assign c[3] = g2[2];
  assign c[4] = g2[3];

  // 4. Post-processing (Sum bits)
  wire [3:0] sum_bits;
  assign sum_bits[0] = p[0] ^ c[0];
  assign sum_bits[1] = p[1] ^ c[1];
  assign sum_bits[2] = p[2] ^ c[2];
  assign sum_bits[3] = p[3] ^ c[3];

  // 5. Final Sum Output
  assign sum = {c[4], sum_bits};

endmodule