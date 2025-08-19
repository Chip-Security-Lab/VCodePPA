//SystemVerilog
module nand2_10 (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [15:0] Y
);
    wire [15:0] dadda_mult_out;

    // Instantiation of the Dadda multiplier submodule
    dadda_multiplier_8x8 u_dadda_multiplier_8x8 (
        .multiplicand (A),
        .multiplier   (B),
        .product      (dadda_mult_out)
    );

    // Instantiation of output register submodule
    nand2_reg_16bit u_nand2_reg_16bit (
        .clk   (1'b1),    // Tie-off with logic high for compatibility (no clock in original)
        .din   (dadda_mult_out),
        .dout  (Y)
    );

endmodule

// -----------------------------------------------------------------------------
// Dadda Multiplier for 8-bit operands, outputs 16-bit product
// -----------------------------------------------------------------------------
module dadda_multiplier_8x8 (
    input  wire [7:0] multiplicand,
    input  wire [7:0] multiplier,
    output reg  [15:0] product
);
    // Partial product matrix
    wire [7:0] pp [7:0];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_partial_products
            assign pp[i] = multiplier[i] ? multiplicand : 8'b0;
        end
    endgenerate

    // Dadda reduction stages
    // All sums and carries are combinational

    // Stage 1: Partial products are generated

    // Stage 2: First reduction using (3,2) and (2,2) counters (Full and Half Adders)
    wire [15:0] sum1, carry1;
    wire [15:0] sum2, carry2;
    wire [15:0] sum3, carry3;

    // Column 0
    assign sum1[0]   = pp[0][0];
    assign carry1[0] = 1'b0;

    // Column 1
    wire ha1_s1, ha1_c1;
    half_adder u_ha1_1 (.a(pp[0][1]), .b(pp[1][0]), .sum(ha1_s1), .carry(ha1_c1));
    assign sum1[1]   = ha1_s1;
    assign carry1[1] = ha1_c1;

    // Column 2
    wire fa1_s1, fa1_c1;
    full_adder u_fa1_1 (.a(pp[0][2]), .b(pp[1][1]), .cin(pp[2][0]), .sum(fa1_s1), .carry(fa1_c1));
    assign sum1[2]   = fa1_s1;
    assign carry1[2] = fa1_c1;

    // Column 3
    wire fa1_s2, fa1_c2;
    full_adder u_fa1_2 (.a(pp[0][3]), .b(pp[1][2]), .cin(pp[2][1]), .sum(fa1_s2), .carry(fa1_c2));
    wire ha1_s2, ha1_c2;
    half_adder u_ha1_2 (.a(pp[3][0]), .b(fa1_s2), .sum(ha1_s2), .carry(ha1_c2));
    assign sum1[3]   = ha1_s2;
    assign carry1[3] = ha1_c2 | fa1_c2;

    // Column 4
    wire fa1_s3, fa1_c3;
    full_adder u_fa1_3 (.a(pp[0][4]), .b(pp[1][3]), .cin(pp[2][2]), .sum(fa1_s3), .carry(fa1_c3));
    wire fa1_s4, fa1_c4;
    full_adder u_fa1_4 (.a(pp[3][1]), .b(pp[4][0]), .cin(fa1_s3), .sum(fa1_s4), .carry(fa1_c4));
    assign sum1[4]   = fa1_s4;
    assign carry1[4] = fa1_c4 | fa1_c3;

    // Column 5
    wire fa1_s5, fa1_c5;
    full_adder u_fa1_5 (.a(pp[0][5]), .b(pp[1][4]), .cin(pp[2][3]), .sum(fa1_s5), .carry(fa1_c5));
    wire fa1_s6, fa1_c6;
    full_adder u_fa1_6 (.a(pp[3][2]), .b(pp[4][1]), .cin(pp[5][0]), .sum(fa1_s6), .carry(fa1_c6));
    wire ha1_s3, ha1_c3;
    half_adder u_ha1_3 (.a(fa1_s5), .b(fa1_s6), .sum(ha1_s3), .carry(ha1_c3));
    assign sum1[5]   = ha1_s3;
    assign carry1[5] = ha1_c3 | fa1_c5 | fa1_c6;

    // Column 6
    wire fa1_s7, fa1_c7;
    full_adder u_fa1_7 (.a(pp[0][6]), .b(pp[1][5]), .cin(pp[2][4]), .sum(fa1_s7), .carry(fa1_c7));
    wire fa1_s8, fa1_c8;
    full_adder u_fa1_8 (.a(pp[3][3]), .b(pp[4][2]), .cin(pp[5][1]), .sum(fa1_s8), .carry(fa1_c8));
    wire fa1_s9, fa1_c9;
    full_adder u_fa1_9 (.a(pp[6][0]), .b(fa1_s7), .cin(fa1_s8), .sum(fa1_s9), .carry(fa1_c9));
    assign sum1[6]   = fa1_s9;
    assign carry1[6] = fa1_c9 | fa1_c7 | fa1_c8;

    // Column 7
    wire fa1_s10, fa1_c10;
    full_adder u_fa1_10 (.a(pp[0][7]), .b(pp[1][6]), .cin(pp[2][5]), .sum(fa1_s10), .carry(fa1_c10));
    wire fa1_s11, fa1_c11;
    full_adder u_fa1_11 (.a(pp[3][4]), .b(pp[4][3]), .cin(pp[5][2]), .sum(fa1_s11), .carry(fa1_c11));
    wire fa1_s12, fa1_c12;
    full_adder u_fa1_12 (.a(pp[6][1]), .b(fa1_s10), .cin(fa1_s11), .sum(fa1_s12), .carry(fa1_c12));
    assign sum1[7]   = fa1_s12;
    assign carry1[7] = fa1_c12 | fa1_c10 | fa1_c11;

    // Column 8
    wire fa1_s13, fa1_c13;
    full_adder u_fa1_13 (.a(pp[1][7]), .b(pp[2][6]), .cin(pp[3][5]), .sum(fa1_s13), .carry(fa1_c13));
    wire fa1_s14, fa1_c14;
    full_adder u_fa1_14 (.a(pp[4][4]), .b(pp[5][3]), .cin(pp[6][2]), .sum(fa1_s14), .carry(fa1_c14));
    wire fa1_s15, fa1_c15;
    full_adder u_fa1_15 (.a(pp[7][0]), .b(fa1_s13), .cin(fa1_s14), .sum(fa1_s15), .carry(fa1_c15));
    assign sum1[8]   = fa1_s15;
    assign carry1[8] = fa1_c15 | fa1_c13 | fa1_c14;

    // Column 9
    wire fa1_s16, fa1_c16;
    full_adder u_fa1_16 (.a(pp[2][7]), .b(pp[3][6]), .cin(pp[4][5]), .sum(fa1_s16), .carry(fa1_c16));
    wire fa1_s17, fa1_c17;
    full_adder u_fa1_17 (.a(pp[5][4]), .b(pp[6][3]), .cin(pp[7][1]), .sum(fa1_s17), .carry(fa1_c17));
    wire ha1_s4, ha1_c4;
    half_adder u_ha1_4 (.a(fa1_s16), .b(fa1_s17), .sum(ha1_s4), .carry(ha1_c4));
    assign sum1[9]   = ha1_s4;
    assign carry1[9] = ha1_c4 | fa1_c16 | fa1_c17;

    // Column 10
    wire fa1_s18, fa1_c18;
    full_adder u_fa1_18 (.a(pp[3][7]), .b(pp[4][6]), .cin(pp[5][5]), .sum(fa1_s18), .carry(fa1_c18));
    wire fa1_s19, fa1_c19;
    full_adder u_fa1_19 (.a(pp[6][4]), .b(pp[7][2]), .cin(fa1_s18), .sum(fa1_s19), .carry(fa1_c19));
    assign sum1[10]   = fa1_s19;
    assign carry1[10] = fa1_c19 | fa1_c18;

    // Column 11
    wire fa1_s20, fa1_c20;
    full_adder u_fa1_20 (.a(pp[4][7]), .b(pp[5][6]), .cin(pp[6][5]), .sum(fa1_s20), .carry(fa1_c20));
    wire ha1_s5, ha1_c5;
    half_adder u_ha1_5 (.a(pp[7][3]), .b(fa1_s20), .sum(ha1_s5), .carry(ha1_c5));
    assign sum1[11]   = ha1_s5;
    assign carry1[11] = ha1_c5 | fa1_c20;

    // Column 12
    wire fa1_s21, fa1_c21;
    full_adder u_fa1_21 (.a(pp[5][7]), .b(pp[6][6]), .cin(pp[7][4]), .sum(fa1_s21), .carry(fa1_c21));
    assign sum1[12]   = fa1_s21;
    assign carry1[12] = fa1_c21;

    // Column 13
    wire ha1_s6, ha1_c6;
    half_adder u_ha1_6 (.a(pp[6][7]), .b(pp[7][5]), .sum(ha1_s6), .carry(ha1_c6));
    assign sum1[13]   = ha1_s6;
    assign carry1[13] = ha1_c6;

    // Column 14
    assign sum1[14]   = pp[7][6];
    assign carry1[14] = 1'b0;

    // Column 15
    assign sum1[15]   = pp[7][7];
    assign carry1[15] = 1'b0;

    // Second reduction stage
    // Now, add sum1 and carry1 (carry shifted left by 1), using a fast carry-propagate adder
    wire [15:0] sum_final;
    wire        carry_dummy;
    carry_lookahead_adder_16bit u_cla16 (
        .a      (sum1),
        .b      ({carry1[14:0],1'b0}),
        .sum    (sum_final),
        .carry  (carry_dummy)
    );

    always @(*) begin
        product = sum_final;
    end

endmodule

// -----------------------------------------------------------------------------
// Output register submodule (16-bit register with enable always high)
// -----------------------------------------------------------------------------
module nand2_reg_16bit (
    input  wire clk,          // Clock input, tied to 1'b1 for combinational behavior
    input  wire [15:0] din,   // Data input
    output reg  [15:0] dout   // Registered output
);
    // Latch the output value (functionally equivalent to always @* in the original)
    always @(*) begin
        dout <= din;
    end
endmodule

// -----------------------------------------------------------------------------
// Full Adder
// -----------------------------------------------------------------------------
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire carry
);
    assign sum  = a ^ b ^ cin;
    assign carry = (a & b) | (a & cin) | (b & cin);
endmodule

// -----------------------------------------------------------------------------
// Half Adder
// -----------------------------------------------------------------------------
module half_adder (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire carry
);
    assign sum  = a ^ b;
    assign carry = a & b;
endmodule

// -----------------------------------------------------------------------------
// 16-bit Carry Lookahead Adder
// -----------------------------------------------------------------------------
module carry_lookahead_adder_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] sum,
    output wire        carry
);
    wire [15:0] g, p, c;

    assign g = a & b;        // generate
    assign p = a ^ b;        // propagate

    assign c[0] = 1'b0;
    assign c[1]  = g[0]  | (p[0]  & c[0]);
    assign c[2]  = g[1]  | (p[1]  & c[1]);
    assign c[3]  = g[2]  | (p[2]  & c[2]);
    assign c[4]  = g[3]  | (p[3]  & c[3]);
    assign c[5]  = g[4]  | (p[4]  & c[4]);
    assign c[6]  = g[5]  | (p[5]  & c[5]);
    assign c[7]  = g[6]  | (p[6]  & c[6]);
    assign c[8]  = g[7]  | (p[7]  & c[7]);
    assign c[9]  = g[8]  | (p[8]  & c[8]);
    assign c[10] = g[9]  | (p[9]  & c[9]);
    assign c[11] = g[10] | (p[10] & c[10]);
    assign c[12] = g[11] | (p[11] & c[11]);
    assign c[13] = g[12] | (p[12] & c[12]);
    assign c[14] = g[13] | (p[13] & c[13]);
    assign c[15] = g[14] | (p[14] & c[14]);

    assign sum[0]  = p[0]  ^ c[0];
    assign sum[1]  = p[1]  ^ c[1];
    assign sum[2]  = p[2]  ^ c[2];
    assign sum[3]  = p[3]  ^ c[3];
    assign sum[4]  = p[4]  ^ c[4];
    assign sum[5]  = p[5]  ^ c[5];
    assign sum[6]  = p[6]  ^ c[6];
    assign sum[7]  = p[7]  ^ c[7];
    assign sum[8]  = p[8]  ^ c[8];
    assign sum[9]  = p[9]  ^ c[9];
    assign sum[10] = p[10] ^ c[10];
    assign sum[11] = p[11] ^ c[11];
    assign sum[12] = p[12] ^ c[12];
    assign sum[13] = p[13] ^ c[13];
    assign sum[14] = p[14] ^ c[14];
    assign sum[15] = p[15] ^ c[15];
    assign carry   = g[15] | (p[15] & c[15]);
endmodule