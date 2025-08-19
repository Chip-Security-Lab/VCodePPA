module Adder_1(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    localparam N = 4;

    // Stage 1: Pre-processing (Generate, Propagate, XOR)
    // s1_xor_bits[i] = A[i] ^ B[i]
    // s1_propagate[i] = A[i] | B[i] (standard prefix propagate)
    // s1_generate[i] = A[i] & B[i] (standard prefix generate)
    wire [N-1:0] s1_xor_bits;
    wire [N-1:0] s1_propagate;
    wire [N-1:0] s1_generate;

    assign s1_xor_bits  = A ^ B;
    assign s1_propagate = A | B;
    assign s1_generate  = A & B;


    // Stage 2: Prefix Tree Level 0 (Initial GG/PP pairs for range [i:i])
    // s2_gg_lvl0[i] = s1_generate[i]
    // s2_pp_lvl0[i] = s1_propagate[i]
    wire [N-1:0] s2_gg_lvl0;
    wire [N-1:0] s2_pp_lvl0;

    assign s2_gg_lvl0 = s1_generate;
    assign s2_pp_lvl0 = s1_propagate;


    // Stage 3: Prefix Tree Level 1 (Combine range [i:i-1] from [i:i] and [i-1:i-1])
    // s3_gg_lvl1[i] = s2_gg_lvl0[i] | (s2_pp_lvl0[i] & s2_gg_lvl0[i-1])
    // s3_pp_lvl1[i] = s2_pp_lvl0[i] & s2_pp_lvl0[i-1]
    wire [N-1:0] s3_gg_lvl1;
    wire [N-1:0] s3_pp_lvl1;

    // i=0: Pass-through for range [0:0]
    assign s3_gg_lvl1[0] = s2_gg_lvl0[0];
    assign s3_pp_lvl1[0] = s2_pp_lvl0[0];

    // i=1: Combine [1:1] and [0:0] -> [1:0]
    assign s3_gg_lvl1[1] = s2_gg_lvl0[1] | (s2_pp_lvl0[1] & s2_gg_lvl0[0]);
    assign s3_pp_lvl1[1] = s2_pp_lvl0[1] & s2_pp_lvl0[0];

    // i=2: Combine [2:2] and [1:1] -> [2:1]
    assign s3_gg_lvl1[2] = s2_gg_lvl0[2] | (s2_pp_lvl0[2] & s2_gg_lvl0[1]);
    assign s3_pp_lvl1[2] = s2_pp_lvl0[2] & s2_pp_lvl0[1];

    // i=3: Combine [3:3] and [2:2] -> [3:2]
    assign s3_gg_lvl1[3] = s2_gg_lvl0[3] | (s2_pp_lvl0[3] & s2_gg_lvl0[2]);
    assign s3_pp_lvl1[3] = s2_pp_lvl0[3] & s2_pp_lvl0[2];


    // Stage 4: Prefix Tree Level 2 (Combine range [i:i-3] from [i:i-1] and [i-2:i-3])
    // We only need specific GG[i][0] for carries c[i+1]
    // c[1] needs GG[0][0] = s2_gg_lvl0[0] (range [0:0])
    // c[2] needs GG[1][0] = s3_gg_lvl1[1] (range [1:0])
    // c[3] needs GG[2][0]. Combine GG[2][1] (s3_gg_lvl1[2]) and GG[0][0] (s2_gg_lvl0[0]).
    // c[4] needs GG[3][0]. Combine GG[3][2] (s3_gg_lvl1[3]) and GG[1][0] (s3_gg_lvl1[1]).

    wire s4_gg_for_c3; // Represents GG[2][0]
    wire s4_gg_for_c4; // Represents GG[3][0]

    // Calculate GG[2][0] (Range [2:0]) by combining GG[2][1] (from level 1) and GG[0][0] (from level 0)
    assign s4_gg_for_c3 = s3_gg_lvl1[2] | (s3_pp_lvl1[2] & s2_gg_lvl0[0]);

    // Calculate GG[3][0] (Range [3:0]) by combining GG[3][2] (from level 1) and GG[1][0] (from level 1)
    assign s4_gg_for_c4 = s3_gg_lvl1[3] | (s3_pp_lvl1[3] & s3_gg_lvl1[1]);


    // Stage 5: Carry Calculation
    // s5_carries[i] is carry-in to bit i
    wire [N:0] s5_carries;

    assign s5_carries[0] = 1'b0; // External carry-in is 0

    // c1 = GG[0][0]
    assign s5_carries[1] = s2_gg_lvl0[0];

    // c2 = GG[1][0]
    assign s5_carries[2] = s3_gg_lvl1[1];

    // c3 = GG[2][0]
    assign s5_carries[3] = s4_gg_for_c3;

    // c4 = GG[3][0] (Carry-out)
    assign s5_carries[4] = s4_gg_for_c4;


    // Stage 6: Sum Calculation
    // s6_sum_bits[i] = (A[i]^B[i]) ^ c[i] = s1_xor_bits[i] ^ s5_carries[i]
    wire [N-1:0] s6_sum_bits;

    assign s6_sum_bits = s1_xor_bits ^ s5_carries[N-1:0];


    // Final Output Assignment
    // sum = {c[N], s[N-1:0]}
    assign sum = {s5_carries[N], s6_sum_bits};

endmodule