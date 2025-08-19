//SystemVerilog
// 8-bit adder using Han-Carlson parallel prefix logic
module adder_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);

// Internal signals for generate and propagate
wire [7:0] g; // g[i] = a[i] & b[i] (carry generated)
wire [7:0] p; // p[i] = a[i] ^ b[i] (carry propagated)

// Internal signals for group propagate and generate (PG) pairs {G, P}
// gp_sX[Y] represents the {G, P} pair for a block at stage X, starting at index Y
// Stage 0: span 1, gp_s0[i] = {g[i], p[i]}
wire [1:0] gp_s0 [7:0];
// Stage 1: span 2, gp_s1[k] covers block [2*k+1 : 2*k]
wire [1:0] gp_s1 [3:0]; // Indices 0, 1, 2, 3 correspond to blocks [1:0], [3:2], [5:4], [7:6]
// Stage 2: span 4, gp_s2[k] covers block [4*k+3 : 4*k]
wire [1:0] gp_s2 [1:0]; // Indices 0, 1 correspond to blocks [3:0], [7:4]
// Stage 3: span 8, gp_s3[k] covers block [8*k+7 : 8*k]
wire [1:0] gp_s3 [0:0]; // Index 0 corresponds to block [7:0]

// Internal signals for carries
// c[i] is the carry into bit i
wire [8:0] c; // Need carries from c[0] to c[8]

// 1. Pre-processing: Calculate initial generate and propagate signals
assign p = a ^ b;
assign g = a & b;

// Stage 0: Initial PG pairs
genvar i;
generate
  for (i = 0; i < 8; i = i + 1) begin : stage0_gen
    assign gp_s0[i] = {g[i], p[i]};
  end
endgenerate

// 2. Carry-tree computation (Han-Carlson structure)

// Stage 1 (span 2)
// gp_s1[k] = combine(gp_s0[2*k+1], gp_s0[2*k])
assign {gp_s1[0][0], gp_s1[0][1]} = {gp_s0[1][0] | (gp_s0[1][1] & gp_s0[0][0]), gp_s0[1][1] & gp_s0[0][1]}; // G(1,0), P(1,0)
assign {gp_s1[1][0], gp_s1[1][1]} = {gp_s0[3][0] | (gp_s0[3][1] & gp_s0[2][0]), gp_s0[3][1] & gp_s0[2][1]}; // G(3,2), P(3,2)
assign {gp_s1[2][0], gp_s1[2][1]} = {gp_s0[5][0] | (gp_s0[5][1] & gp_s0[4][0]), gp_s0[5][1] & gp_s0[4][1]}; // G(5,4), P(5,4)
assign {gp_s1[3][0], gp_s1[3][1]} = {gp_s0[7][0] | (gp_s0[7][1] & gp_s0[6][0]), gp_s0[7][1] & gp_s0[6][1]}; // G(7,6), P(7,6)

// Stage 2 (span 4)
// gp_s2[k] = combine(gp_s1[2*k+1], gp_s1[2*k])
// Indices for gp_s1 inputs: [1], [0]; [3], [2]
assign {gp_s2[0][0], gp_s2[0][1]} = {gp_s1[1][0] | (gp_s1[1][1] & gp_s1[0][0]), gp_s1[1][1] & gp_s1[0][1]}; // G(3,0), P(3,0)
assign {gp_s2[1][0], gp_s2[1][1]} = {gp_s1[3][0] | (gp_s1[3][1] & gp_s1[2][0]), gp_s1[3][1] & gp_s1[2][1]}; // G(7,4), P(7,4)

// Stage 3 (span 8)
// gp_s3[0] = combine(gp_s2[1], gp_s2[0])
assign {gp_s3[0][0], gp_s3[0][1]} = {gp_s2[1][0] | (gp_s2[1][1] & gp_s2[0][0]), gp_s2[1][1] & gp_s2[0][1]}; // G(7,0), P(7,0)

// 3. Calculate carries c[1]...c[8] from G/P terms
// c[0] is the input carry (assumed 0 for A+B)
assign c[0] = 1'b0;

// Carries derived from tree outputs and intermediate combinations
// c[i+1] = G[i:0] | (P[i:0] & c[0])
// Since c[0] = 0, c[i+1] = G[i:0]

assign c[1] = gp_s0[0][0]; // G(0,0)
assign c[2] = gp_s1[0][0]; // G(1,0)
assign c[3] = gp_s0[2][0] | (gp_s0[2][1] & c[2]); // G(2,0) = G(2,2) | (P(2,2) & G(1,0))
assign c[4] = gp_s2[0][0]; // G(3,0)
assign c[5] = gp_s0[4][0] | (gp_s0[4][1] & c[4]); // G(4,0) = G(4,4) | (P(4,4) & G(3,0))
assign c[6] = gp_s1[2][0] | (gp_s1[2][1] & c[4]); // G(5,0) = G(5,4) | (P(5,4) & G(3,0))
assign c[7] = gp_s0[6][0] | (gp_s0[6][1] & c[6]); // G(6,0) = G(6,6) | (P(6,6) & G(5,0))
assign c[8] = gp_s3[0][0]; // G(7,0) - Final carry-out

// 4. Calculate sum bits
// sum[i] = p[i] ^ c[i]
assign sum = p ^ c[7:0];

endmodule