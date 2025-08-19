//SystemVerilog
module adder_8_cla (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);

  // Internal signals for generate and propagate at bit level
  wire [7:0] p; // Propagate: a[i] ^ b[i]
  wire [7:0] g; // Generate: a[i] & b[i]

  // Internal signals for group generate and propagate (4-bit groups)
  wire [1:0] P; // Group Propagate
  wire [1:0] G; // Group Generate

  // Internal signals for carries
  // c_bit[i] is the carry-in to bit i
  wire [7:0] c_bit;

  // c_group[j] is the carry-in to group j
  // c_group[0] is carry-in to group 0 (bits 0-3)
  // c_group[1] is carry-in to group 1 (bits 4-7)
  // c_group[2] is carry-out of group 1 (overall carry-out)
  wire [2:0] c_group;


  // 1. Calculate bit-level generate and propagate
  assign p = a ^ b;
  assign g = a & b;

  // Assume no external carry-in for the 8-bit adder
  assign c_group[0] = 1'b0; // Overall carry-in is 0

  // 2. Calculate group-level generate and propagate (4-bit groups)
  // Group 0 (bits 0-3)
  assign G[0] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
  assign P[0] = p[3] & p[2] & p[1] & p[0];

  // Group 1 (bits 4-7)
  assign G[1] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]);
  assign P[1] = p[7] & p[6] & p[5] & p[4];

  // 3. Calculate group carries using CLA logic
  // c_group[0] is already assigned (overall carry-in)
  // c_group[1] is carry-out of group 0, carry-in to group 1
  assign c_group[1] = G[0] | (P[0] & c_group[0]);
  // c_group[2] is carry-out of group 1 (overall carry-out)
  assign c_group[2] = G[1] | (P[1] & c_group[1]); // Not used for sum output

  // 4. Calculate bit-level carries using group carries (Optimized using parallel boolean expressions)
  // Group 0 (bits 0-3), carry-in c_group[0]
  assign c_bit[0] = c_group[0];
  assign c_bit[1] = g[0] | (p[0] & c_group[0]);
  assign c_bit[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c_group[0]);
  assign c_bit[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c_group[0]);

  // Group 1 (bits 4-7), carry-in c_group[1]
  assign c_bit[4] = c_group[1];
  assign c_bit[5] = g[4] | (p[4] & c_group[1]);
  assign c_bit[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c_group[1]);
  assign c_bit[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & c_group[1]);

  // 5. Calculate sum bits
  assign sum = p ^ c_bit;

endmodule