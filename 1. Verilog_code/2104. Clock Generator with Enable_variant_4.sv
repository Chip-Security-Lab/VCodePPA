//SystemVerilog
module clk_gen_with_enable(
    input wire i_ref_clk,   // Reference clock input
    input wire i_rst,       // Active high reset
    input wire i_enable,    // Module enable
    input wire [7:0] i_multiplicand, // 8-bit multiplicand
    input wire [7:0] i_multiplier,   // 8-bit multiplier
    output reg o_clk,       // Clock output
    output reg [15:0] o_product      // 16-bit multiplication result
);

    wire [15:0] dadda_product;

    dadda_multiplier_8bit u_dadda_multiplier (
        .multiplicand(i_multiplicand),
        .multiplier(i_multiplier),
        .product(dadda_product)
    );

    always @(*) begin
        if (i_enable) begin
            o_clk = i_ref_clk;
        end else begin
            o_clk = 1'b0;
        end
    end

    always @(posedge i_ref_clk or posedge i_rst) begin
        if (i_rst)
            o_product <= 16'd0;
        else if (i_enable)
            o_product <= dadda_product;
    end

endmodule

// Dadda 8x8 multiplier module (IEEE 1364-2005 compliant)
module dadda_multiplier_8bit(
    input  wire [7:0] multiplicand,
    input  wire [7:0] multiplier,
    output wire [15:0] product
);

    wire [7:0] pp [7:0]; // Partial products

    // Generate partial products
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : gen_pp
            assign pp[i] = multiplicand & {8{multiplier[i]}};
        end
    endgenerate

    // Stage 1: First reduction (Dadda, max height 6)
    wire [15:0] s1, c1;
    wire [15:0] s2, c2;
    wire [15:0] s3, c3;
    wire [15:0] s4, c4;
    wire [15:0] s5, c5;
    wire [15:0] s6, c6;

    // Column-wise addition using half and full adders
    // Bit 0
    assign product[0] = pp[0][0];

    // Bit 1
    half_adder ha1_1(.a(pp[0][1]), .b(pp[1][0]), .sum(s1[1]), .carry(c1[1]));
    assign product[1] = s1[1];

    // Bit 2
    full_adder fa2_1(.a(pp[0][2]), .b(pp[1][1]), .cin(pp[2][0]), .sum(s1[2]), .carry(c1[2]));
    assign product[2] = s1[2];

    // Bit 3
    full_adder fa3_1(.a(pp[0][3]), .b(pp[1][2]), .cin(pp[2][1]), .sum(s1[3]), .carry(c1[3]));
    full_adder fa3_2(.a(s1[3]), .b(pp[3][0]), .cin(1'b0), .sum(s2[3]), .carry(c2[3]));
    assign product[3] = s2[3];

    // Bit 4
    full_adder fa4_1(.a(pp[0][4]), .b(pp[1][3]), .cin(pp[2][2]), .sum(s1[4]), .carry(c1[4]));
    full_adder fa4_2(.a(s1[4]), .b(pp[3][1]), .cin(pp[4][0]), .sum(s2[4]), .carry(c2[4]));
    half_adder ha4_3(.a(s2[4]), .b(c1[3]), .sum(s3[4]), .carry(c3[4]));
    assign product[4] = s3[4];

    // Bit 5
    full_adder fa5_1(.a(pp[0][5]), .b(pp[1][4]), .cin(pp[2][3]), .sum(s1[5]), .carry(c1[5]));
    full_adder fa5_2(.a(s1[5]), .b(pp[3][2]), .cin(pp[4][1]), .sum(s2[5]), .carry(c2[5]));
    full_adder fa5_3(.a(s2[5]), .b(pp[5][0]), .cin(c1[4]), .sum(s3[5]), .carry(c3[5]));
    half_adder ha5_4(.a(s3[5]), .b(c2[3]), .sum(s4[5]), .carry(c4[5]));
    assign product[5] = s4[5];

    // Bit 6
    full_adder fa6_1(.a(pp[0][6]), .b(pp[1][5]), .cin(pp[2][4]), .sum(s1[6]), .carry(c1[6]));
    full_adder fa6_2(.a(s1[6]), .b(pp[3][3]), .cin(pp[4][2]), .sum(s2[6]), .carry(c2[6]));
    full_adder fa6_3(.a(s2[6]), .b(pp[5][1]), .cin(pp[6][0]), .sum(s3[6]), .carry(c3[6]));
    full_adder fa6_4(.a(s3[6]), .b(c1[5]), .cin(c2[4]), .sum(s4[6]), .carry(c4[6]));
    half_adder ha6_5(.a(s4[6]), .b(c3[5]), .sum(s5[6]), .carry(c5[6]));
    assign product[6] = s5[6];

    // Bit 7
    full_adder fa7_1(.a(pp[0][7]), .b(pp[1][6]), .cin(pp[2][5]), .sum(s1[7]), .carry(c1[7]));
    full_adder fa7_2(.a(s1[7]), .b(pp[3][4]), .cin(pp[4][3]), .sum(s2[7]), .carry(c2[7]));
    full_adder fa7_3(.a(s2[7]), .b(pp[5][2]), .cin(pp[6][1]), .sum(s3[7]), .carry(c3[7]));
    full_adder fa7_4(.a(s3[7]), .b(pp[7][0]), .cin(c1[6]), .sum(s4[7]), .carry(c4[7]));
    full_adder fa7_5(.a(s4[7]), .b(c2[5]), .cin(c3[6]), .sum(s5[7]), .carry(c5[7]));
    half_adder ha7_6(.a(s5[7]), .b(c4[6]), .sum(s6[7]), .carry(c6[7]));
    assign product[7] = s6[7];

    // Bit 8
    full_adder fa8_1(.a(pp[1][7]), .b(pp[2][6]), .cin(pp[3][5]), .sum(s1[8]), .carry(c1[8]));
    full_adder fa8_2(.a(s1[8]), .b(pp[4][4]), .cin(pp[5][3]), .sum(s2[8]), .carry(c2[8]));
    full_adder fa8_3(.a(s2[8]), .b(pp[6][2]), .cin(pp[7][1]), .sum(s3[8]), .carry(c3[8]));
    full_adder fa8_4(.a(s3[8]), .b(c1[7]), .cin(c2[7]), .sum(s4[8]), .carry(c4[8]));
    full_adder fa8_5(.a(s4[8]), .b(c3[7]), .cin(c4[7]), .sum(s5[8]), .carry(c5[8]));
    half_adder ha8_6(.a(s5[8]), .b(c5[7]), .sum(s6[8]), .carry(c6[8]));
    assign product[8] = s6[8];

    // Bit 9
    full_adder fa9_1(.a(pp[2][7]), .b(pp[3][6]), .cin(pp[4][5]), .sum(s1[9]), .carry(c1[9]));
    full_adder fa9_2(.a(s1[9]), .b(pp[5][4]), .cin(pp[6][3]), .sum(s2[9]), .carry(c2[9]));
    full_adder fa9_3(.a(s2[9]), .b(pp[7][2]), .cin(c1[8]), .sum(s3[9]), .carry(c3[9]));
    full_adder fa9_4(.a(s3[9]), .b(c2[8]), .cin(c3[8]), .sum(s4[9]), .carry(c4[9]));
    full_adder fa9_5(.a(s4[9]), .b(c4[8]), .cin(c5[8]), .sum(s5[9]), .carry(c5[9]));
    half_adder ha9_6(.a(s5[9]), .b(c6[8]), .sum(s6[9]), .carry(c6[9]));
    assign product[9] = s6[9];

    // Bit 10
    full_adder fa10_1(.a(pp[3][7]), .b(pp[4][6]), .cin(pp[5][5]), .sum(s1[10]), .carry(c1[10]));
    full_adder fa10_2(.a(s1[10]), .b(pp[6][4]), .cin(pp[7][3]), .sum(s2[10]), .carry(c2[10]));
    full_adder fa10_3(.a(s2[10]), .b(c1[9]), .cin(c2[9]), .sum(s3[10]), .carry(c3[10]));
    full_adder fa10_4(.a(s3[10]), .b(c3[9]), .cin(c4[9]), .sum(s4[10]), .carry(c4[10]));
    full_adder fa10_5(.a(s4[10]), .b(c5[9]), .cin(c6[9]), .sum(s5[10]), .carry(c5[10]));
    assign product[10] = s5[10];

    // Bit 11
    full_adder fa11_1(.a(pp[4][7]), .b(pp[5][6]), .cin(pp[6][5]), .sum(s1[11]), .carry(c1[11]));
    full_adder fa11_2(.a(s1[11]), .b(pp[7][4]), .cin(c1[10]), .sum(s2[11]), .carry(c2[11]));
    full_adder fa11_3(.a(s2[11]), .b(c2[10]), .cin(c3[10]), .sum(s3[11]), .carry(c3[11]));
    full_adder fa11_4(.a(s3[11]), .b(c4[10]), .cin(c5[10]), .sum(s4[11]), .carry(c4[11]));
    assign product[11] = s4[11];

    // Bit 12
    full_adder fa12_1(.a(pp[5][7]), .b(pp[6][6]), .cin(pp[7][5]), .sum(s1[12]), .carry(c1[12]));
    full_adder fa12_2(.a(s1[12]), .b(c1[11]), .cin(c2[11]), .sum(s2[12]), .carry(c2[12]));
    full_adder fa12_3(.a(s2[12]), .b(c3[11]), .cin(c4[11]), .sum(s3[12]), .carry(c3[12]));
    assign product[12] = s3[12];

    // Bit 13
    full_adder fa13_1(.a(pp[6][7]), .b(pp[7][6]), .cin(c1[12]), .sum(s1[13]), .carry(c1[13]));
    full_adder fa13_2(.a(s1[13]), .b(c2[12]), .cin(c3[12]), .sum(s2[13]), .carry(c2[13]));
    assign product[13] = s2[13];

    // Bit 14
    full_adder fa14_1(.a(pp[7][7]), .b(c1[13]), .cin(c2[13]), .sum(s1[14]), .carry(c1[14]));
    assign product[14] = s1[14];

    // Bit 15
    assign product[15] = c1[14];

endmodule

// Half adder module
module half_adder(
    input  wire a,
    input  wire b,
    output wire sum,
    output wire carry
);
    assign sum = a ^ b;
    assign carry = a & b;
endmodule

// Full adder module
module full_adder(
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire carry
);
    assign sum = a ^ b ^ cin;
    assign carry = (a & b) | (a & cin) | (b & cin);
endmodule