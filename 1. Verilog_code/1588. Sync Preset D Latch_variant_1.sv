//SystemVerilog
module wallace_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    // Partial products generation
    wire [7:0] pp [7:0];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            assign pp[i] = a & {8{b[i]}};
        end
    endgenerate

    // First stage reduction
    wire [7:0] s1 [3:0];
    wire [7:0] c1 [3:0];
    
    // First level of reduction
    full_adder fa1_0 (pp[0][0], pp[1][0], pp[2][0], s1[0][0], c1[0][0]);
    full_adder fa1_1 (pp[0][1], pp[1][1], pp[2][1], s1[0][1], c1[0][1]);
    full_adder fa1_2 (pp[0][2], pp[1][2], pp[2][2], s1[0][2], c1[0][2]);
    full_adder fa1_3 (pp[0][3], pp[1][3], pp[2][3], s1[0][3], c1[0][3]);
    full_adder fa1_4 (pp[0][4], pp[1][4], pp[2][4], s1[0][4], c1[0][4]);
    full_adder fa1_5 (pp[0][5], pp[1][5], pp[2][5], s1[0][5], c1[0][5]);
    full_adder fa1_6 (pp[0][6], pp[1][6], pp[2][6], s1[0][6], c1[0][6]);
    full_adder fa1_7 (pp[0][7], pp[1][7], pp[2][7], s1[0][7], c1[0][7]);

    // Second stage reduction
    wire [7:0] s2 [1:0];
    wire [7:0] c2 [1:0];
    
    // Second level of reduction
    full_adder fa2_0 (s1[0][0], c1[0][0], pp[3][0], s2[0][0], c2[0][0]);
    full_adder fa2_1 (s1[0][1], c1[0][1], pp[3][1], s2[0][1], c2[0][1]);
    full_adder fa2_2 (s1[0][2], c1[0][2], pp[3][2], s2[0][2], c2[0][2]);
    full_adder fa2_3 (s1[0][3], c1[0][3], pp[3][3], s2[0][3], c2[0][3]);
    full_adder fa2_4 (s1[0][4], c1[0][4], pp[3][4], s2[0][4], c2[0][4]);
    full_adder fa2_5 (s1[0][5], c1[0][5], pp[3][5], s2[0][5], c2[0][5]);
    full_adder fa2_6 (s1[0][6], c1[0][6], pp[3][6], s2[0][6], c2[0][6]);
    full_adder fa2_7 (s1[0][7], c1[0][7], pp[3][7], s2[0][7], c2[0][7]);

    // Final stage reduction
    wire [7:0] sum;
    wire [7:0] carry;
    
    // Final level of reduction
    full_adder fa3_0 (s2[0][0], c2[0][0], pp[4][0], sum[0], carry[0]);
    full_adder fa3_1 (s2[0][1], c2[0][1], pp[4][1], sum[1], carry[1]);
    full_adder fa3_2 (s2[0][2], c2[0][2], pp[4][2], sum[2], carry[2]);
    full_adder fa3_3 (s2[0][3], c2[0][3], pp[4][3], sum[3], carry[3]);
    full_adder fa3_4 (s2[0][4], c2[0][4], pp[4][4], sum[4], carry[4]);
    full_adder fa3_5 (s2[0][5], c2[0][5], pp[4][5], sum[5], carry[5]);
    full_adder fa3_6 (s2[0][6], c2[0][6], pp[4][6], sum[6], carry[6]);
    full_adder fa3_7 (s2[0][7], c2[0][7], pp[4][7], sum[7], carry[7]);

    // Final addition
    assign product = {carry, sum} + {pp[5], pp[6], pp[7]};

endmodule

module full_adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule