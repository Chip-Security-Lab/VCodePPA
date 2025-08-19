//SystemVerilog
module adder_4 (
  input [2:0] a,
  input [2:0] b,
  output [3:0] sum
);

  // Brent-Kung Adder (3-bit)

  // Level 0: Generate and Propagate signals
  wire [2:0] p; // Propagate
  wire [2:0] g; // Generate

  assign p[0] = a[0] ^ b[0];
  assign g[0] = a[0] & b[0];
  assign p[1] = a[1] ^ b[1];
  assign g[1] = a[1] & b[1];
  assign p[2] = a[2] ^ b[2];
  assign g[2] = a[2] & b[2];

  // Level 1: Prefix network (distance 1)
  // (P_i:i-1, G_i:i-1)
  wire P_1_0, G_1_0; // Combine bits 1 and 0
  wire P_2_1, G_2_1; // Combine bits 2 and 1

  assign P_1_0 = p[1] & p[0];
  assign G_1_0 = g[1] | (p[1] & g[0]);

  assign P_2_1 = p[2] & p[1];
  assign G_2_1 = g[2] | (p[2] & g[1]);

  // Level 2: Prefix network (distance 2)
  // (P_i:i-3, G_i:i-3)
  // For n=3, this is combining (P_2:1, G_2:1) with (p0, g0) to get (P_2:0, G_2:0)
  wire P_2_0, G_2_0; // Combine bits 2 down to 0

  assign P_2_0 = P_2_1 & p[0]; // P_2:0 = P_2:1 & P_0:0
  assign G_2_0 = G_2_1 | (P_2_1 & g[0]); // G_2:0 = G_2:1 | (P_2:1 & G_0:0)

  // Carries (c_i is carry INTO bit i, c_0 = Cin)
  wire c_0 = 1'b0; // Assuming no carry-in
  wire c_1 = g[0];
  wire c_2 = G_1_0;
  wire c_3 = G_2_0; // Final carry-out

  // Sum bits
  assign sum[0] = p[0] ^ c_0; // sum[0] = p[0]
  assign sum[1] = p[1] ^ c_1; // sum[1] = p[1] ^ g[0]
  assign sum[2] = p[2] ^ c_2; // sum[2] = p[2] ^ G_1_0
  assign sum[3] = c_3;       // sum[3] = G_2_0

endmodule