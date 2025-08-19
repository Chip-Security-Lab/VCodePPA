module Adder_7_pipelined (
    input wire clk,
    input wire reset,
    input wire [3:0] A,
    input wire [3:0] B,
    output reg [4:0] sum // Registered sum output
);

    //--------------------------------------------------------------------------
    // Stage 1: Calculate Generate (G) and Propagate (P) signals
    // These are combinational from inputs A and B.
    //--------------------------------------------------------------------------
    wire [3:0] P_stage1; // Propagate: A[i] ^ B[i]
    wire [3:0] G_stage1; // Generate:  A[i] & B[i]

    assign P_stage1 = A ^ B;
    assign G_stage1 = A & B;

    // Register P and G for the next stage
    reg [3:0] P_stage2_q;
    reg [3:0] G_stage2_q;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            P_stage2_q <= 4'b0;
            G_stage2_q <= 4'b0;
        end else begin
            P_stage2_q <= P_stage1;
            G_stage2_q <= G_stage1;
        end
    end

    //--------------------------------------------------------------------------
    // Stage 2: Calculate Carries (C) and Sum (S)
    // This stage uses the registered P and G signals from Stage 1.
    //--------------------------------------------------------------------------
    wire [4:0] C_stage2; // Carries, C[0] is input carry (assumed 0)
    wire [4:0] sum_stage2_comb; // Combinational sum before output register

    // Input Carry (C0) for Stage 2
    assign C_stage2[0] = 1'b0; // Assuming no input carry for A+B

    // Calculate Carries using parallel Carry-Lookahead logic
    // using registered P and G signals (P_stage2_q, G_stage2_q)
    assign C_stage2[1] = G_stage2_q[0] | (P_stage2_q[0] & C_stage2[0]); // C1 = G0 + P0.C0 -> C1 = G0
    assign C_stage2[2] = G_stage2_q[1] | (P_stage2_q[1] & C_stage2[1]); // C2 = G1 + P1.C1
    assign C_stage2[3] = G_stage2_q[2] | (P_stage2_q[2] & C_stage2[2]); // C3 = G2 + P2.C2
    assign C_stage2[4] = G_stage2_q[3] | (P_stage2_q[3] & C_stage2[3]); // C4 = G3 + P3.C3

    // Calculate Sum bits using registered P and calculated Carries
    assign sum_stage2_comb[0] = P_stage2_q[0] ^ C_stage2[0]; // S0 = P0 ^ C0 -> S0 = P0
    assign sum_stage2_comb[1] = P_stage2_q[1] ^ C_stage2[1]; // S1 = P1 ^ C1
    assign sum_stage2_comb[2] = P_stage2_q[2] ^ C_stage2[2]; // S2 = P2 ^ C2
    assign sum_stage2_comb[3] = P_stage2_q[3] ^ C_stage2[3]; // S3 = P3 ^ C3

    // The most significant bit of the sum is the final carry out C4
    assign sum_stage2_comb[4] = C_stage2[4];

    // Register the final sum output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sum <= 5'b0;
        end else begin
            sum <= sum_stage2_comb;
        end
    end

endmodule