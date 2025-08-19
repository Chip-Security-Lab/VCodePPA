//SystemVerilog
module wallace_multiplier_4x4 (
    input [3:0] A,
    input [3:0] B,
    output [7:0] P
);

    // Partial Products (4x4 = 16 bits)
    wire pp00 = A[0] & B[0];
    wire pp01 = A[0] & B[1];
    wire pp02 = A[0] & B[2];
    wire pp03 = A[0] & B[3];
    wire pp10 = A[1] & B[0];
    wire pp11 = A[1] & B[1];
    wire pp12 = A[1] & B[2];
    wire pp13 = A[1] & B[3];
    wire pp20 = A[2] & B[0];
    wire pp21 = A[2] & B[1];
    wire pp22 = A[2] & B[2];
    wire pp23 = A[2] & B[3];
    wire pp30 = A[3] & B[0];
    wire pp31 = A[3] & B[1];
    wire pp32 = A[3] & B[2];
    wire pp33 = A[3] & B[3];

    // Intermediate wires for simplified FA logic (carry = (a&b) | ((a^b)&c_in))
    wire xor_pp02_pp11;
    wire and_pp02_pp11;
    wire and_xor_pp02_pp11_pp20;

    wire xor_pp03_pp12;
    wire and_pp03_pp12;
    wire and_xor_pp03_pp12_pp21;

    wire xor_c3a_c3b;
    wire and_c3a_c3b;
    wire and_xor_c3a_c3b_s4;

    wire xor_c4_pp23;
    wire and_c4_pp23;
    wire and_xor_c4_pp23_pp32;

    // Reduction Layer 1 (using Full Adders and Half Adders logic)
    // Column 2 (weight 2^2): pp02, pp11, pp20 -> s2_l1, c2_l1
    // Original: s2_l1 = pp02 ^ pp11 ^ pp20; c2_l1 = (pp02 & pp11) | (pp02 & pp20) | (pp11 & pp20);
    assign xor_pp02_pp11 = pp02 ^ pp11;
    wire s2_l1 = xor_pp02_pp11 ^ pp20;
    assign and_pp02_pp11 = pp02 & pp11;
    assign and_xor_pp02_pp11_pp20 = xor_pp02_pp11 & pp20;
    wire c2_l1 = and_pp02_pp11 | and_xor_pp02_pp11_pp20;

    // Column 3 (weight 2^3): pp03, pp12, pp21, pp30
    // FA(pp03, pp12, pp21) -> s3a_l1, c3a_l1 (c3a_l1 has weight 2^4)
    // Original: s3a_l1 = pp03 ^ pp12 ^ pp21; c3a_l1 = (pp03 & pp12) | (pp03 & pp21) | (pp12 & pp21);
    assign xor_pp03_pp12 = pp03 ^ pp12;
    wire s3a_l1 = xor_pp03_pp12 ^ pp21;
    assign and_pp03_pp12 = pp03 & pp12;
    assign and_xor_pp03_pp12_pp21 = xor_pp03_pp12 & pp21;
    wire c3a_l1 = and_pp03_pp12 | and_xor_pp03_pp12_pp21;

    // HA(s3a_l1, pp30) -> s3b_l1, c3b_l1 (c3b_l1 has weight 2^4)
    wire s3b_l1 = s3a_l1 ^ pp30;
    wire c3b_l1 = s3a_l1 & pp30;

    // Column 4 (weight 2^4): pp13, pp22, pp31 -> s4_l1, c4_l1 (c4_l1 has weight 2^5)
    // Original: s4_l1 = pp13 ^ pp22 ^ pp31; c4_l1 = (pp13 & pp22) | (pp13 & pp31) | (pp22 & pp31);
    // This FA is not directly used in the next layer as a group of 3, but its outputs are.
    // Let's keep the standard form here as it's simpler and its outputs are mixed with others later.
    wire s4_l1 = pp13 ^ pp22 ^ pp31;
    wire c4_l1 = (pp13 & pp22) | (pp13 & pp31) | (pp22 & pp31);


    // Bits after Layer 1 reduction, grouped by weight:
    // w=0: pp00 (1)
    // w=1: pp01, pp10 (2)
    // w=2: s2_l1 (1)
    // w=3: c2_l1, s3b_l1 (2)
    // w=4: c3a_l1, c3b_l1, s4_l1 (3)
    // w=5: c4_l1, pp23, pp32 (3)
    // w=6: pp33 (1)

    // Reduction Layer 2
    // Column 4 (weight 2^4): c3a_l1, c3b_l1, s4_l1 -> s4_l2, c4_l2 (c4_l2 has weight 2^5)
    // Original: s4_l2 = c3a_l1 ^ c3b_l1 ^ s4_l1; c4_l2 = (c3a_l1 & c3b_l1) | (c3a_l1 & s4_l1) | (c3b_l1 & s4_l1);
    assign xor_c3a_c3b = c3a_l1 ^ c3b_l1;
    wire s4_l2 = xor_c3a_c3b ^ s4_l1;
    assign and_c3a_c3b = c3a_l1 & c3b_l1;
    assign and_xor_c3a_c3b_s4 = xor_c3a_c3b & s4_l1;
    wire c4_l2 = and_c3a_c3b | and_xor_c3a_c3b_s4;

    // Column 5 (weight 2^5): c4_l1, pp23, pp32 -> s5_l2, c5_l2 (c5_l2 has weight 2^6)
    // Original: s5_l2 = c4_l1 ^ pp23 ^ pp32; c5_l2 = (c4_l1 & pp23) | (c4_l1 & pp32) | (pp23 & pp32);
    assign xor_c4_pp23 = c4_l1 ^ pp23;
    wire s5_l2 = xor_c4_pp23 ^ pp32;
    assign and_c4_pp23 = c4_l1 & pp23;
    assign and_xor_c4_pp23_pp32 = xor_c4_pp23 & pp32;
    wire c5_l2 = and_c4_pp23 | and_xor_c4_pp23_pp32;

    // Bits after Layer 2 reduction, grouped by weight (inputs to CPA):
    // w=0: pp00 (1)
    // w=1: pp01, pp10 (2)
    // w=2: s2_l1 (1)
    // w=3: c2_l1, s3b_l1 (2)
    // w=4: s4_l2 (1)
    // w=5: c4_l2, s5_l2 (2)
    // w=6: c5_l2, pp33 (2)

    // Final Carry-Propagate Adder (CPA) inputs
    // Assemble two 8-bit vectors from the reduced bits
    wire [7:0] cpa_in1, cpa_in2;

    // Vector 1: sum bits and single bits from each column
    assign cpa_in1[0] = pp00;       // weight 2^0
    assign cpa_in1[1] = pp01;       // weight 2^1 (one bit from pair)
    assign cpa_in1[2] = s2_l1;      // weight 2^2 (single bit)
    assign cpa_in1[3] = c2_l1;      // weight 2^3 (one bit from pair)
    assign cpa_in1[4] = s4_l2;      // weight 2^4 (single bit)
    assign cpa_in1[5] = c4_l2;      // weight 2^5 (one bit from pair)
    assign cpa_in1[6] = c5_l2;      // weight 2^6 (one bit from pair)
    assign cpa_in1[7] = 1'b0;       // MSB padding

    // Vector 2: the other bits from pairs, shifted left by 1 position
    assign cpa_in2[0] = 1'b0;       // No carry into LSB
    assign cpa_in2[1] = pp10;       // weight 2^1 (the other bit from pair)
    assign cpa_in2[2] = 1'b0;       // s2_l1 was single
    assign cpa_in2[3] = s3b_l1;     // weight 2^3 (the other bit from pair)
    assign cpa_in2[4] = 1'b0;       // s4_l2 was single
    assign cpa_in2[5] = s5_l2;     // weight 2^5 (the other bit from pair)
    assign cpa_in2[6] = pp33;       // weight 2^6 (the other bit from pair)
    assign cpa_in2[7] = 1'b0;       // MSB padding

    // Final CPA (built-in Verilog '+' operator infers an adder)
    assign P = cpa_in1 + cpa_in2;

endmodule