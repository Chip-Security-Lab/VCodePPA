module Adder_6(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Kogge-Stone Adder Implementation (4-bit)

    // Wires for Propagate (P) and Generate (G) signals at different stages
    wire [3:0] P_stage0; // Initial P
    wire [3:0] G_stage0; // Initial G

    wire [3:0] P_stage1; // P after stage 1 (step=1)
    wire [3:0] G_stage1; // G after stage 1 (step=1)

    wire [3:0] P_stage2; // P after stage 2 (step=2) - Final stage for 4 bits

    // Note: G_stage2 is not explicitly needed for carries in the standard Kogge-Stone formulation
    // as carries[i+1] = G_i^(log2 N). We can directly calculate carries from P/G of previous stages.
    // However, for clarity and structure following the (P_i^k, G_i^k) pair definition,
    // we can define G_stage2 and use it for carries. Let's use G_stage2.
    wire [3:0] G_stage2;


    // Wires for carries
    wire [4:0] carries; // carries[0] is input carry, carries[1..4] are internal/output carries

    // Assume input carry is 0 for simple addition (A + B)
    assign carries[0] = 1'b0;

    // Stage 0: Initial P and G (bit-wise)
    // P_i^0 = A_i ^ B_i
    // G_i^0 = A_i & B_i
    assign P_stage0[0] = A[0] ^ B[0];
    assign G_stage0[0] = A[0] & B[0];
    assign P_stage0[1] = A[1] ^ B[1];
    assign G_stage0[1] = A[1] & B[1];
    assign P_stage0[2] = A[2] ^ B[2];
    assign G_stage0[2] = A[2] & B[2];
    assign P_stage0[3] = A[3] ^ B[3];
    assign G_stage0[3] = A[3] & B[3];

    // Stage 1: Step = 1 (Black cells and Gray cells)
    // (P_i^1, G_i^1) = (P_i^0 & P_{i-1}^0, G_i^0 | (P_i^0 & G_{i-1}^0)) for i >= 1
    // (P_0^1, G_0^1) = (P_0^0, G_0^0)
    // i=0 (Gray cell)
    assign P_stage1[0] = P_stage0[0];
    assign G_stage1[0] = G_stage0[0];
    // i=1 (Black cell)
    assign P_stage1[1] = P_stage0[1] & P_stage0[0];
    assign G_stage1[1] = G_stage0[1] | (P_stage0[1] & G_stage0[0]);
    // i=2 (Black cell)
    assign P_stage1[2] = P_stage0[2] & P_stage0[1];
    assign G_stage1[2] = G_stage0[2] | (P_stage0[2] & G_stage0[1]);
    // i=3 (Black cell)
    assign P_stage1[3] = P_stage0[3] & P_stage0[2];
    assign G_stage1[3] = G_stage0[3] | (P_stage0[3] & G_stage0[2]);

    // Stage 2: Step = 2 (Black cells and Gray cells - Final stage for carries)
    // (P_i^2, G_i^2) = (P_i^1 & P_{i-2}^1, G_i^1 | (P_i^1 & G_{i-2}^1)) for i >= 2
    // (P_i^2, G_i^2) = (P_i^1, G_i^1) for i < 2
    // i=0 (Gray cell)
    assign P_stage2[0] = P_stage1[0];
    assign G_stage2[0] = G_stage1[0];
    // i=1 (Gray cell)
    assign P_stage2[1] = P_stage1[1];
    assign G_stage2[1] = G_stage1[1];
    // i=2 (Black cell)
    assign P_stage2[2] = P_stage1[2] & P_stage1[0]; // Depends on i-2 = 0
    assign G_stage2[2] = G_stage1[2] | (P_stage1[2] & G_stage1[0]); // Depends on i-2 = 0
    // i=3 (Black cell)
    assign P_stage2[3] = P_stage1[3] & P_stage1[1]; // Depends on i-2 = 1
    assign G_stage2[3] = G_stage1[3] | (P_stage1[3] & G_stage1[1]); // Depends on i-2 = 1

    // Calculate carries from final stage G signals
    // carries[i+1] = G_i^2
    assign carries[1] = G_stage2[0];
    assign carries[2] = G_stage2[1];
    assign carries[3] = G_stage2[2];
    assign carries[4] = G_stage2[3]; // This is the carry-out

    // Calculate sum bits
    // sum[i] = P_i^0 ^ carries[i]
    assign sum[0] = P_stage0[0] ^ carries[0];
    assign sum[1] = P_stage0[1] ^ carries[1];
    assign sum[2] = P_stage0[2] ^ carries[2];
    assign sum[3] = P_stage0[3] ^ carries[3];

    // The carry-out of the most significant bit is the most significant bit of the sum
    assign sum[4] = carries[4];

endmodule