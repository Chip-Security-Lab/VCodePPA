module Adder_9(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

// Han-Carlson Adder (4-bit)

// Bit-level propagate and generate signals
wire [3:0] p; // propagate: A[i] ^ B[i]
wire [3:0] g; // generate:  A[i] & B[i]

// Group propagate and generate signals (intermediate nodes in prefix tree)
// Naming convention: GP_endBit_startBit, PP_endBit_startBit
// Level 1 (step=1)
wire GP1_0, PP1_0; // G1:0, P1:0
wire GP3_2, PP3_2; // G3:2, P3:2

// Level 2 (step=2)
wire GP2_0, PP2_0; // G2:0, P2:0
wire GP3_0, PP3_0; // G3:0, P3:0

// Carries into each bit position (c[i] is carry into bit i)
// c[0] is the input carry (0)
// c[1] is carry-out of bit 0 (carry into bit 1)
// c[2] is carry-out of bit 1 (carry into bit 2)
// c[3] is carry-out of bit 2 (carry into bit 3)
// c[4] is carry-out of bit 3 (overall carry-out)
wire [4:0] c;

// Sum bits
wire [3:0] sum_bits;

// 1. Calculate bit-level propagate and generate
assign p = A ^ B;
assign g = A & B;

// Set input carry (c0)
assign c[0] = 1'b0;

// 2. Calculate group propagate and generate signals (Prefix Tree)

// Level 1 (step=1)
// (G_i:i-1, P_i:i-1) = (g_i, p_i) * (g_i-1, p_i-1) = (g_i | (p_i & g_i-1), p_i & p_i-1)
assign GP1_0 = g[1] | (p[1] & g[0]); // G1:0
assign PP1_0 = p[1] & p[0];         // P1:0

assign GP3_2 = g[3] | (p[3] & g[2]); // G3:2
assign PP3_2 = p[3] & p[2];         // P3:2

// Level 2 (step=2)
// (G_i:j, P_i:j) = (G_i:k, P_i:k) * (G_k-1:j, P_k-1:j)
// Han-Carlson specific structure for N=4:
// G2:0 = G2:2 * G1:0  => (g2, p2) * (G1:0, P1:0)
assign GP2_0 = g[2] | (p[2] & GP1_0);
assign PP2_0 = p[2] & PP1_0; // P2:0 = p2 & P1:0

// G3:0 = G3:2 * G1:0  => (G3:2, P3:2) * (G1:0, P1:0)
assign GP3_0 = GP3_2 | (PP3_2 & GP1_0);
assign PP3_0 = PP3_2 & PP1_0; // P3:0 = P3:2 & P1:0

// 3. Calculate carries c[1] to c[4] using the group signals and c[0]=0
// c[i] = G_i-1:0 | (P_i-1:0 & c[0])
assign c[1] = g[0];   // c1 = G0:0 | P0:0 & c0 = g0 | p0 & 0 = g0
assign c[2] = GP1_0;  // c2 = G1:0 | P1:0 & c0 = G10 | P10 & 0 = G10
assign c[3] = GP2_0;  // c3 = G2:0 | P2:0 & c0 = G20 | P20 & 0 = G20
assign c[4] = GP3_0;  // c4 = G3:0 | P3:0 & c0 = G30 | P30 & 0 = G30

// 4. Calculate sum bits
// s_i = p_i ^ c_i
assign sum_bits[0] = p[0] ^ c[0]; // s0 = p0 ^ 0 = p0
assign sum_bits[1] = p[1] ^ c[1]; // s1 = p1 ^ c1
assign sum_bits[2] = p[2] ^ c[2]; // s2 = p2 ^ c2
assign sum_bits[3] = p[3] ^ c[3]; // s3 = p3 ^ c3

// 5. Concatenate final sum
assign sum = {c[4], sum_bits};

endmodule