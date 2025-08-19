module Adder_3 (
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

// Pre-processing: Generate (g) and Propagate (p) signals
wire [3:0] p;
wire [3:0] g;

assign p = A ^ B;
assign g = A & B;

// Brent-Kung Prefix Tree for Carry Calculation
// Intermediate Group Generate (G) and Propagate (P) signals
// Notation: gp_Lx_y_z_g/p -> Group Prop/Gen at Level x, range y down to z

// Level 1 (Black cells)
wire gp_L1_1_0_g, gp_L1_1_0_p;
wire gp_L1_3_2_g, gp_L1_3_2_p;

assign gp_L1_1_0_g = g[1] | (p[1] & g[0]);
assign gp_L1_1_0_p = p[1] & p[0];

assign gp_L1_3_2_g = g[3] | (p[3] & g[2]);
assign gp_L1_3_2_p = p[3] & p[2];

// Level 2 (Black cell - Forward pass)
wire gp_L2_3_0_g, gp_L2_3_0_p;

assign gp_L2_3_0_g = gp_L1_3_2_g | (gp_L1_3_2_p & gp_L1_1_0_g);
assign gp_L2_3_0_p = gp_L1_3_2_p & gp_L1_1_0_p;

// Level 2 (Gray cell - Backward pass)
wire gp_L2_2_0_g, gp_L2_2_0_p;

assign gp_L2_2_0_g = g[2] | (p[2] & gp_L1_1_0_g);
assign gp_L2_2_0_p = p[2]; // Gray cell P output is just P_left

// Carry signals (c[i] is carry-in for bit i)
wire [4:0] c; // c[0] is input carry, c[4] is carry-out

// Input carry (implicit 0)
assign c[0] = 1'b0;

// Carries derived from G signals (with c[0]=0)
// c[i] = G[i-1:0] | (P[i-1:0] & c[0])
assign c[1] = g[0];          // G[0:0]
assign c[2] = gp_L1_1_0_g;    // G[1:0]
assign c[3] = gp_L2_2_0_g;    // G[2:0]
assign c[4] = gp_L2_3_0_g;    // G[3:0] (Carry-out)

// Sum bits
wire [3:0] s;

assign s[0] = p[0] ^ c[0];
assign s[1] = p[1] ^ c[1];
assign s[2] = p[2] ^ c[2];
assign s[3] = p[3] ^ c[3];

// Final sum output: Concatenate the carry-out (c[4]) and the sum bits (s[3:0])
assign sum = {c[4], s[3:0]};

endmodule