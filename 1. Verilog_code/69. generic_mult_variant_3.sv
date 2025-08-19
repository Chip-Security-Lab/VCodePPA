//SystemVerilog
module generic_mult #(parameter WIDTH=8) (
    input [WIDTH-1:0] operand1,
    input [WIDTH-1:0] operand2,
    output [2*WIDTH-1:0] product
);
    // Generate partial products
    wire [WIDTH-1:0] pp[WIDTH-1:0];
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pp_rows
            for (j = 0; j < WIDTH; j = j + 1) begin: gen_pp_cols
                assign pp[i][j] = operand1[j] & operand2[i];
            end
        end
    endgenerate

    // Dadda reduction (for WIDTH=8)
    // Stage 1: Reduce from 8 to 6 rows
    wire [13:0] s1_0, c1_0;  // Sum and carry from first reduction
    wire [12:0] s1_1, c1_1;  // Sum and carry from second reduction
    
    // First full adder group in stage 1
    full_adder fa1_0(.a(pp[0][6]), .b(pp[1][5]), .cin(pp[2][4]), .sum(s1_0[6]), .cout(c1_0[6]));
    full_adder fa1_1(.a(pp[3][3]), .b(pp[4][2]), .cin(pp[5][1]), .sum(s1_0[7]), .cout(c1_0[7]));
    full_adder fa1_2(.a(pp[0][7]), .b(pp[1][6]), .cin(pp[2][5]), .sum(s1_0[8]), .cout(c1_0[8]));
    full_adder fa1_3(.a(pp[3][4]), .b(pp[4][3]), .cin(pp[5][2]), .sum(s1_0[9]), .cout(c1_0[9]));
    full_adder fa1_4(.a(pp[6][1]), .b(pp[7][0]), .cin(pp[1][7]), .sum(s1_0[10]), .cout(c1_0[10]));
    full_adder fa1_5(.a(pp[2][6]), .b(pp[3][5]), .cin(pp[4][4]), .sum(s1_0[11]), .cout(c1_0[11]));
    full_adder fa1_6(.a(pp[5][3]), .b(pp[6][2]), .cin(pp[7][1]), .sum(s1_0[12]), .cout(c1_0[12]));
    full_adder fa1_7(.a(pp[2][7]), .b(pp[3][6]), .cin(pp[4][5]), .sum(s1_0[13]), .cout(c1_0[13]));
    
    // Second full adder group in stage 1
    full_adder fa1_8(.a(pp[5][4]), .b(pp[6][3]), .cin(pp[7][2]), .sum(s1_1[10]), .cout(c1_1[10]));
    full_adder fa1_9(.a(pp[3][7]), .b(pp[4][6]), .cin(pp[5][5]), .sum(s1_1[11]), .cout(c1_1[11]));
    full_adder fa1_10(.a(pp[6][4]), .b(pp[7][3]), .cin(1'b0), .sum(s1_1[12]), .cout(c1_1[12]));
    
    // Stage 2: Reduce from 6 to 4 rows
    wire [14:0] s2_0, c2_0;  // Sum and carry from first reduction
    wire [13:0] s2_1, c2_1;  // Sum and carry from second reduction
    
    // Assign direct connections for bits 0-5
    assign s2_0[0] = pp[0][0];
    assign s2_0[1] = pp[0][1];
    assign s2_0[2] = pp[0][2];
    assign s2_0[3] = pp[0][3];
    assign s2_0[4] = pp[0][4];
    assign s2_0[5] = pp[0][5];
    
    // First full adder group in stage 2
    full_adder fa2_0(.a(pp[1][0]), .b(pp[2][0]), .cin(pp[3][0]), .sum(s2_0[6]), .cout(c2_0[6]));
    full_adder fa2_1(.a(pp[1][1]), .b(pp[2][1]), .cin(pp[3][1]), .sum(s2_0[7]), .cout(c2_0[7]));
    full_adder fa2_2(.a(pp[1][2]), .b(pp[2][2]), .cin(pp[3][2]), .sum(s2_0[8]), .cout(c2_0[8]));
    full_adder fa2_3(.a(pp[1][3]), .b(pp[2][3]), .cin(pp[4][0]), .sum(s2_0[9]), .cout(c2_0[9]));
    full_adder fa2_4(.a(pp[1][4]), .b(pp[6][0]), .cin(s1_0[6]), .sum(s2_0[10]), .cout(c2_0[10]));
    full_adder fa2_5(.a(s1_0[7]), .b(s1_0[8]), .cin(c1_0[6]), .sum(s2_0[11]), .cout(c2_0[11]));
    full_adder fa2_6(.a(s1_0[9]), .b(s1_0[10]), .cin(c1_0[7]), .sum(s2_0[12]), .cout(c2_0[12]));
    full_adder fa2_7(.a(s1_0[11]), .b(s1_0[12]), .cin(c1_0[8]), .sum(s2_0[13]), .cout(c2_0[13]));
    full_adder fa2_8(.a(s1_0[13]), .b(s1_1[10]), .cin(c1_0[9]), .sum(s2_0[14]), .cout(c2_0[14]));
    
    // Second full adder group in stage 2
    full_adder fa2_9(.a(c1_0[10]), .b(s1_1[11]), .cin(c1_1[10]), .sum(s2_1[11]), .cout(c2_1[11]));
    full_adder fa2_10(.a(c1_0[11]), .b(s1_1[12]), .cin(c1_1[11]), .sum(s2_1[12]), .cout(c2_1[12]));
    full_adder fa2_11(.a(c1_0[12]), .b(pp[4][7]), .cin(c1_1[12]), .sum(s2_1[13]), .cout(c2_1[13]));
    
    // Stage 3: Reduce from 4 to 2 rows
    wire [15:0] s3, c3;
    
    // Assign direct connections for bit 0
    assign s3[0] = s2_0[0];
    
    // Half adder for bit 1
    half_adder ha3_0(.a(s2_0[1]), .b(pp[4][1]), .sum(s3[1]), .cout(c3[1]));
    
    // Full adders for remaining bits
    full_adder fa3_0(.a(s2_0[2]), .b(pp[4][2]), .cin(pp[5][0]), .sum(s3[2]), .cout(c3[2]));
    full_adder fa3_1(.a(s2_0[3]), .b(pp[4][3]), .cin(pp[5][1]), .sum(s3[3]), .cout(c3[3]));
    full_adder fa3_2(.a(s2_0[4]), .b(pp[4][4]), .cin(pp[5][2]), .sum(s3[4]), .cout(c3[4]));
    full_adder fa3_3(.a(s2_0[5]), .b(pp[4][5]), .cin(pp[5][3]), .sum(s3[5]), .cout(c3[5]));
    full_adder fa3_4(.a(s2_0[6]), .b(c2_0[6]), .cin(pp[5][4]), .sum(s3[6]), .cout(c3[6]));
    full_adder fa3_5(.a(s2_0[7]), .b(c2_0[7]), .cin(pp[5][5]), .sum(s3[7]), .cout(c3[7]));
    full_adder fa3_6(.a(s2_0[8]), .b(c2_0[8]), .cin(pp[5][6]), .sum(s3[8]), .cout(c3[8]));
    full_adder fa3_7(.a(s2_0[9]), .b(c2_0[9]), .cin(pp[5][7]), .sum(s3[9]), .cout(c3[9]));
    full_adder fa3_8(.a(s2_0[10]), .b(c2_0[10]), .cin(pp[6][5]), .sum(s3[10]), .cout(c3[10]));
    full_adder fa3_9(.a(s2_0[11]), .b(c2_0[11]), .cin(pp[6][6]), .sum(s3[11]), .cout(c3[11]));
    full_adder fa3_10(.a(s2_0[12]), .b(c2_0[12]), .cin(pp[6][7]), .sum(s3[12]), .cout(c3[12]));
    full_adder fa3_11(.a(s2_0[13]), .b(c2_0[13]), .cin(pp[7][6]), .sum(s3[13]), .cout(c3[13]));
    full_adder fa3_12(.a(s2_0[14]), .b(c2_0[14]), .cin(pp[7][7]), .sum(s3[14]), .cout(c3[14]));
    full_adder fa3_13(.a(s2_1[13]), .b(c2_1[13]), .cin(c2_1[12]), .sum(s3[15]), .cout(c3[15]));
    
    // Final addition using carry lookahead adder
    wire [15:0] final_sum;
    wire [15:0] final_carry;
    
    // First bit no carry
    assign final_sum[0] = s3[0];
    assign final_carry[0] = 1'b0;
    
    // Carry lookahead adder implementation
    wire [15:0] g, p; // Generate and propagate signals
    wire [15:0] carry;
    
    // Generate and propagate signals
    assign g[0] = s3[0] & c3[0];
    assign p[0] = s3[0] ^ c3[0];
    
    genvar k;
    generate
        for (k = 1; k < 16; k = k + 1) begin: gen_gp
            assign g[k] = s3[k] & c3[k];
            assign p[k] = s3[k] ^ c3[k];
        end
    endgenerate
    
    // Carry lookahead logic
    assign carry[0] = 1'b0;
    assign carry[1] = g[0] | (p[0] & 1'b0);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & 1'b0);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & 1'b0);
    
    // 4-bit carry lookahead blocks
    wire [3:0] block_g, block_p;
    wire [3:0] block_carry;
    
    // Block 0 (bits 0-3)
    assign block_g[0] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign block_p[0] = p[3] & p[2] & p[1] & p[0];
    assign block_carry[0] = 1'b0;
    
    // Block 1 (bits 4-7)
    assign block_g[1] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]);
    assign block_p[1] = p[7] & p[6] & p[5] & p[4];
    assign block_carry[1] = block_g[0] | (block_p[0] & block_carry[0]);
    
    // Block 2 (bits 8-11)
    assign block_g[2] = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | (p[11] & p[10] & p[9] & g[8]);
    assign block_p[2] = p[11] & p[10] & p[9] & p[8];
    assign block_carry[2] = block_g[1] | (block_p[1] & block_g[0]) | (block_p[1] & block_p[0] & block_carry[0]);
    
    // Block 3 (bits 12-15)
    assign block_g[3] = g[15] | (p[15] & g[14]) | (p[15] & p[14] & g[13]) | (p[15] & p[14] & p[13] & g[12]);
    assign block_p[3] = p[15] & p[14] & p[13] & p[12];
    assign block_carry[3] = block_g[2] | (block_p[2] & block_g[1]) | (block_p[2] & block_p[1] & block_g[0]) | 
                            (block_p[2] & block_p[1] & block_p[0] & block_carry[0]);
    
    // Generate carries for each bit
    assign carry[4] = g[3] | (p[3] & block_carry[0]);
    assign carry[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & block_carry[0]);
    assign carry[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & block_carry[0]);
    assign carry[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | 
                     (p[6] & p[5] & p[4] & p[3] & block_carry[0]);
    
    assign carry[8] = g[7] | (p[7] & block_carry[1]);
    assign carry[9] = g[8] | (p[8] & g[7]) | (p[8] & p[7] & block_carry[1]);
    assign carry[10] = g[9] | (p[9] & g[8]) | (p[9] & p[8] & g[7]) | (p[9] & p[8] & p[7] & block_carry[1]);
    assign carry[11] = g[10] | (p[10] & g[9]) | (p[10] & p[9] & g[8]) | (p[10] & p[9] & p[8] & g[7]) | 
                      (p[10] & p[9] & p[8] & p[7] & block_carry[1]);
    
    assign carry[12] = g[11] | (p[11] & block_carry[2]);
    assign carry[13] = g[12] | (p[12] & g[11]) | (p[12] & p[11] & block_carry[2]);
    assign carry[14] = g[13] | (p[13] & g[12]) | (p[13] & p[12] & g[11]) | (p[13] & p[12] & p[11] & block_carry[2]);
    assign carry[15] = g[14] | (p[14] & g[13]) | (p[14] & p[13] & g[12]) | (p[14] & p[13] & p[12] & g[11]) | 
                      (p[14] & p[13] & p[12] & p[11] & block_carry[2]);
    
    // Generate final sum
    assign final_sum[0] = s3[0];
    genvar m;
    generate
        for (m = 1; m < 16; m = m + 1) begin: gen_final_sum
            assign final_sum[m] = s3[m] ^ c3[m] ^ carry[m-1];
        end
    endgenerate
    
    // Assign output product
    assign product = final_sum;
endmodule

// Full adder module
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// Half adder module
module half_adder (
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule