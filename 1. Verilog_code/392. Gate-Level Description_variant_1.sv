//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: nand2_12
// Description: Optimized NAND gate implementation with clear data path
///////////////////////////////////////////////////////////////////////////////

module nand2_12 (
    input  wire A,   // Input signal A
    input  wire B,   // Input signal B
    output wire Y    // NAND output Y = !(A & B)
);
    // Intermediate signal to improve readability
    wire and_result;
    
    // Separate AND operation for better control
    assign and_result = A & B;
    
    // Final NAND result
    assign Y = ~and_result;
    
    // Attributes for synthesis optimization
    (* dont_touch = "true" *)
    (* direct_enable = "true" *)
    wire _unused_optimization;
    assign _unused_optimization = 1'b0;

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: dadda_mult_8bit
// Description: 8-bit Dadda tree multiplier implementation
///////////////////////////////////////////////////////////////////////////////

module dadda_mult_8bit (
    input  wire [7:0] A,        // 8-bit multiplicand
    input  wire [7:0] B,        // 8-bit multiplier
    output wire [15:0] PRODUCT  // 16-bit product result
);
    // Stage 0: Generate partial products
    wire [7:0][7:0] pp;
    
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp_rows
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_cols
                assign pp[i][j] = A[j] & B[i];
            end
        end
    endgenerate
    
    // Stage 1: Dadda reduction (height = 6)
    wire [14:0] s1, c1;
    
    // Row with weight 0
    assign PRODUCT[0] = pp[0][0];
    
    // Row with weight 1
    half_adder ha1_1(.a(pp[0][1]), .b(pp[1][0]), .sum(PRODUCT[1]), .cout(c1[0]));
    
    // Row with weight 2
    full_adder fa1_2(.a(pp[0][2]), .b(pp[1][1]), .cin(pp[2][0]), .sum(s1[0]), .cout(c1[1]));
    
    // Row with weight 3
    full_adder fa1_3a(.a(pp[0][3]), .b(pp[1][2]), .cin(pp[2][1]), .sum(s1[1]), .cout(c1[2]));
    half_adder ha1_3(.a(pp[3][0]), .b(s1[0]), .sum(s1[2]), .cout(c1[3]));
    
    // Row with weight 4
    full_adder fa1_4a(.a(pp[0][4]), .b(pp[1][3]), .cin(pp[2][2]), .sum(s1[3]), .cout(c1[4]));
    full_adder fa1_4b(.a(pp[3][1]), .b(pp[4][0]), .cin(c1[0]), .sum(s1[4]), .cout(c1[5]));
    
    // Row with weight 5
    full_adder fa1_5a(.a(pp[0][5]), .b(pp[1][4]), .cin(pp[2][3]), .sum(s1[5]), .cout(c1[6]));
    full_adder fa1_5b(.a(pp[3][2]), .b(pp[4][1]), .cin(pp[5][0]), .sum(s1[6]), .cout(c1[7]));
    
    // Row with weight 6
    full_adder fa1_6a(.a(pp[0][6]), .b(pp[1][5]), .cin(pp[2][4]), .sum(s1[7]), .cout(c1[8]));
    full_adder fa1_6b(.a(pp[3][3]), .b(pp[4][2]), .cin(pp[5][1]), .sum(s1[8]), .cout(c1[9]));
    half_adder ha1_6(.a(pp[6][0]), .b(c1[1]), .sum(s1[9]), .cout(c1[10]));
    
    // Row with weight 7
    full_adder fa1_7a(.a(pp[0][7]), .b(pp[1][6]), .cin(pp[2][5]), .sum(s1[10]), .cout(c1[11]));
    full_adder fa1_7b(.a(pp[3][4]), .b(pp[4][3]), .cin(pp[5][2]), .sum(s1[11]), .cout(c1[12]));
    half_adder ha1_7(.a(pp[6][1]), .b(pp[7][0]), .sum(s1[12]), .cout(c1[13]));
    
    // Stage 2: Dadda reduction (height = 4)
    wire [14:0] s2, c2;
    
    // Row weight 2
    assign PRODUCT[2] = s1[0];
    
    // Row weight 3
    half_adder ha2_3(.a(s1[1]), .b(s1[2]), .sum(PRODUCT[3]), .cout(c2[0]));
    
    // Row weight 4
    full_adder fa2_4(.a(s1[3]), .b(s1[4]), .cin(c1[2]), .sum(s2[0]), .cout(c2[1]));
    
    // Row weight 5
    full_adder fa2_5a(.a(s1[5]), .b(s1[6]), .cin(c1[3]), .sum(s2[1]), .cout(c2[2]));
    half_adder ha2_5(.a(c1[4]), .b(c1[5]), .sum(s2[2]), .cout(c2[3]));
    
    // Row weight 6
    full_adder fa2_6a(.a(s1[7]), .b(s1[8]), .cin(s1[9]), .sum(s2[3]), .cout(c2[4]));
    full_adder fa2_6b(.a(c1[6]), .b(c1[7]), .cin(c2[0]), .sum(s2[4]), .cout(c2[5]));
    
    // Row weight 7
    full_adder fa2_7a(.a(s1[10]), .b(s1[11]), .cin(s1[12]), .sum(s2[5]), .cout(c2[6]));
    full_adder fa2_7b(.a(c1[8]), .b(c1[9]), .cin(c1[10]), .sum(s2[6]), .cout(c2[7]));
    
    // Row weight 8
    full_adder fa2_8a(.a(pp[1][7]), .b(pp[2][6]), .cin(pp[3][5]), .sum(s2[7]), .cout(c2[8]));
    full_adder fa2_8b(.a(pp[4][4]), .b(pp[5][3]), .cin(pp[6][2]), .sum(s2[8]), .cout(c2[9]));
    full_adder fa2_8c(.a(pp[7][1]), .b(c1[11]), .cin(c1[12]), .sum(s2[9]), .cout(c2[10]));
    
    // Stage 3: Dadda reduction (height = 2)
    wire [14:0] s3, c3;
    
    // Row weight 4
    assign PRODUCT[4] = s2[0];
    
    // Row weight 5
    half_adder ha3_5(.a(s2[1]), .b(s2[2]), .sum(PRODUCT[5]), .cout(c3[0]));
    
    // Row weight 6
    full_adder fa3_6(.a(s2[3]), .b(s2[4]), .cin(c2[1]), .sum(PRODUCT[6]), .cout(c3[1]));
    
    // Row weight 7
    full_adder fa3_7(.a(s2[5]), .b(s2[6]), .cin(c2[2]), .sum(s3[0]), .cout(c3[2]));
    
    // Row weight 8
    full_adder fa3_8a(.a(s2[7]), .b(s2[8]), .cin(s2[9]), .sum(s3[1]), .cout(c3[3]));
    full_adder fa3_8b(.a(c2[3]), .b(c2[4]), .cin(c2[5]), .sum(s3[2]), .cout(c3[4]));
    
    // Row weight 9
    full_adder fa3_9a(.a(pp[2][7]), .b(pp[3][6]), .cin(pp[4][5]), .sum(s3[3]), .cout(c3[5]));
    full_adder fa3_9b(.a(pp[5][4]), .b(pp[6][3]), .cin(pp[7][2]), .sum(s3[4]), .cout(c3[6]));
    full_adder fa3_9c(.a(c2[6]), .b(c2[7]), .cin(c2[8]), .sum(s3[5]), .cout(c3[7]));
    
    // Row weight 10
    full_adder fa3_10a(.a(pp[3][7]), .b(pp[4][6]), .cin(pp[5][5]), .sum(s3[6]), .cout(c3[8]));
    full_adder fa3_10b(.a(pp[6][4]), .b(pp[7][3]), .cin(c2[9]), .sum(s3[7]), .cout(c3[9]));
    
    // Row weight 11
    full_adder fa3_11(.a(pp[4][7]), .b(pp[5][6]), .cin(pp[6][5]), .sum(s3[8]), .cout(c3[10]));
    half_adder ha3_11(.a(pp[7][4]), .b(c2[10]), .sum(s3[9]), .cout(c3[11]));
    
    // Row weight 12
    full_adder fa3_12(.a(pp[5][7]), .b(pp[6][6]), .cin(pp[7][5]), .sum(s3[10]), .cout(c3[12]));
    
    // Row weight 13
    half_adder ha3_13(.a(pp[6][7]), .b(pp[7][6]), .sum(s3[11]), .cout(c3[13]));
    
    // Row weight 14
    assign s3[12] = pp[7][7];
    
    // Final stage: Ripple carry adder for remaining stages
    // Bit 7 calculation
    wire s7_and1, s7_and2, s7_and3;
    assign s7_and1 = s3[0] & c3[0];
    assign s7_and2 = s3[0] & c3[1];
    assign s7_and3 = c3[0] & c3[1];
    wire carry7 = s7_and1 | s7_and2 | s7_and3;
    assign PRODUCT[7] = s3[0] ^ c3[0] ^ c3[1];
    
    // Bit 8 calculation
    wire s8_and1, s8_and2, s8_and3;
    assign s8_and1 = s3[1] & s3[2];
    assign s8_and2 = s3[1] & carry7;
    assign s8_and3 = s3[2] & carry7;
    wire carry8 = s8_and1 | s8_and2 | s8_and3;
    assign PRODUCT[8] = s3[1] ^ s3[2] ^ carry7;
    
    // Bit 9 calculation
    wire s9_and1, s9_and2, s9_and3, s9_and4, s9_and5, s9_and6;
    assign s9_and1 = s3[3] & s3[4];
    assign s9_and2 = s3[3] & s3[5];
    assign s9_and3 = s3[3] & carry8;
    assign s9_and4 = s3[4] & s3[5];
    assign s9_and5 = s3[4] & carry8;
    assign s9_and6 = s3[5] & carry8;
    wire carry9 = s9_and1 | s9_and2 | s9_and3 | s9_and4 | s9_and5 | s9_and6;
    assign PRODUCT[9] = s3[3] ^ s3[4] ^ s3[5] ^ carry8;
    
    // Bit 10 calculation
    wire s10_and1, s10_and2, s10_and3, s10_and4, s10_and5, s10_and6;
    assign s10_and1 = s3[6] & s3[7];
    assign s10_and2 = s3[6] & c3[7];
    assign s10_and3 = s3[6] & carry9;
    assign s10_and4 = s3[7] & c3[7];
    assign s10_and5 = s3[7] & carry9;
    assign s10_and6 = c3[7] & carry9;
    wire carry10 = s10_and1 | s10_and2 | s10_and3 | s10_and4 | s10_and5 | s10_and6;
    assign PRODUCT[10] = s3[6] ^ s3[7] ^ c3[7] ^ carry9;
    
    // Bit 11 calculation
    wire s11_and1, s11_and2, s11_and3, s11_and4, s11_and5, s11_and6;
    assign s11_and1 = s3[8] & s3[9];
    assign s11_and2 = s3[8] & c3[9];
    assign s11_and3 = s3[8] & carry10;
    assign s11_and4 = s3[9] & c3[9];
    assign s11_and5 = s3[9] & carry10;
    assign s11_and6 = c3[9] & carry10;
    wire carry11 = s11_and1 | s11_and2 | s11_and3 | s11_and4 | s11_and5 | s11_and6;
    assign PRODUCT[11] = s3[8] ^ s3[9] ^ c3[9] ^ carry10;
    
    // Bit 12 calculation
    wire s12_and1, s12_and2, s12_and3, s12_and4, s12_and5, s12_and6;
    assign s12_and1 = s3[10] & c3[11];
    assign s12_and2 = s3[10] & c3[12];
    assign s12_and3 = s3[10] & carry11;
    assign s12_and4 = c3[11] & c3[12];
    assign s12_and5 = c3[11] & carry11;
    assign s12_and6 = c3[12] & carry11;
    wire carry12 = s12_and1 | s12_and2 | s12_and3 | s12_and4 | s12_and5 | s12_and6;
    assign PRODUCT[12] = s3[10] ^ c3[11] ^ c3[12] ^ carry11;
    
    // Bit 13 calculation
    wire s13_and1, s13_and2, s13_and3, s13_and4, s13_and5, s13_and6;
    assign s13_and1 = s3[11] & c3[12];
    assign s13_and2 = s3[11] & c3[13];
    assign s13_and3 = s3[11] & carry12;
    assign s13_and4 = c3[12] & c3[13];
    assign s13_and5 = c3[12] & carry12;
    assign s13_and6 = c3[13] & carry12;
    wire carry13 = s13_and1 | s13_and2 | s13_and3 | s13_and4 | s13_and5 | s13_and6;
    assign PRODUCT[13] = s3[11] ^ c3[12] ^ c3[13] ^ carry12;
    
    // Bit 14 calculation
    assign PRODUCT[14] = s3[12] ^ c3[13] ^ carry13;
    
    // Bit 15 calculation
    wire s15_and1, s15_and2, s15_and3;
    assign s15_and1 = s3[12] & c3[13];
    assign s15_and2 = s3[12] & carry13;
    assign s15_and3 = c3[13] & carry13;
    assign PRODUCT[15] = s15_and1 | s15_and2 | s15_and3;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: half_adder
// Description: Half adder module for Dadda tree multiplier
///////////////////////////////////////////////////////////////////////////////

module half_adder (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire cout
);
    // Calculate sum
    assign sum = a ^ b;
    
    // Calculate carry
    assign cout = a & b;
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: full_adder
// Description: Full adder module for Dadda tree multiplier
///////////////////////////////////////////////////////////////////////////////

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    // Intermediate signals for clarity
    wire ab_xor;
    wire ab_and;
    wire a_and_cin;
    wire b_and_cin;
    
    // Calculate XOR of inputs a and b
    assign ab_xor = a ^ b;
    
    // Calculate final sum
    assign sum = ab_xor ^ cin;
    
    // Calculate partial carry terms
    assign ab_and = a & b;
    assign a_and_cin = a & cin;
    assign b_and_cin = b & cin;
    
    // Calculate final carry
    assign cout = ab_and | a_and_cin | b_and_cin;
endmodule