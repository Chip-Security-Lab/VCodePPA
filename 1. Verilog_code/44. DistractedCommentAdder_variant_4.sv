//SystemVerilog
module adder_8bit_cla (
  input [7:0] a,
  input [7:0] b,
  input       cin,
  output [7:0] sum,
  output      cout
);

  wire [7:0] g; // Generate signals
  wire [7:0] p; // Propagate signals (using P = A ^ B)
  wire [8:0] c; // Carry signals (c[0] is cin, c[8] is cout)

  wire p0_grp, g0_grp; // Block 0 group propagate and generate
  wire p1_grp, g1_grp; // Block 1 group propagate and generate

  // Assign input carry
  assign c[0] = cin;

  // Level 1: Bit-level Generate and Propagate
  assign g = a & b;
  assign p = a ^ b;

  // Level 2: Block-level Generate and Propagate + Internal Carries
  // Block 0 (bits 0-3)
  assign p0_grp = p[3] & p[2] & p[1] & p[0];
  assign g0_grp = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g0_grp | (p0_grp & c[0]); // Carry out of Block 0

  // Block 1 (bits 4-7)
  assign p1_grp = p[7] & p[6] & p[5] & p[4];
  assign g1_grp = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]);

  assign c[5] = g[4] | (p[4] & c[4]); // c[4] is carry in to Block 1
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  assign c[8] = g1_grp | (p1_grp & c[4]); // Carry out of Block 1

  // Final Carry Out
  assign cout = c[8];

  // Level 3: Sum bits (Sum = P ^ C)
  assign sum = p ^ c[7:0];

endmodule