//SystemVerilog
module wallace_tree_multiplier_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  multiplicand,
    input  wire [7:0]  multiplier,
    output reg  [15:0] product
);
    // Partial products generation
    wire [7:0] pp [7:0];
    
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            for (j = 0; j < 8; j = j + 1) begin : bit_gen
                assign pp[i][j] = multiplier[i] & multiplicand[j];
            end
        end
    endgenerate
    
    // Wallace tree reduction - First stage
    wire [14:0] s1_1, c1_1;
    // Sum and carry for first set of 3 partial products
    full_adder_1bit fa1_1_0(pp[0][0], pp[1][0], pp[2][0], s1_1[0], c1_1[0]);
    full_adder_1bit fa1_1_1(pp[0][1], pp[1][1], pp[2][1], s1_1[1], c1_1[1]);
    full_adder_1bit fa1_1_2(pp[0][2], pp[1][2], pp[2][2], s1_1[2], c1_1[2]);
    full_adder_1bit fa1_1_3(pp[0][3], pp[1][3], pp[2][3], s1_1[3], c1_1[3]);
    full_adder_1bit fa1_1_4(pp[0][4], pp[1][4], pp[2][4], s1_1[4], c1_1[4]);
    full_adder_1bit fa1_1_5(pp[0][5], pp[1][5], pp[2][5], s1_1[5], c1_1[5]);
    full_adder_1bit fa1_1_6(pp[0][6], pp[1][6], pp[2][6], s1_1[6], c1_1[6]);
    full_adder_1bit fa1_1_7(pp[0][7], pp[1][7], pp[2][7], s1_1[7], c1_1[7]);

    // Sum and carry for second set of 3 partial products
    full_adder_1bit fa1_2_0(pp[3][0], pp[4][0], pp[5][0], s1_1[8], c1_1[8]);
    full_adder_1bit fa1_2_1(pp[3][1], pp[4][1], pp[5][1], s1_1[9], c1_1[9]);
    full_adder_1bit fa1_2_2(pp[3][2], pp[4][2], pp[5][2], s1_1[10], c1_1[10]);
    full_adder_1bit fa1_2_3(pp[3][3], pp[4][3], pp[5][3], s1_1[11], c1_1[11]);
    full_adder_1bit fa1_2_4(pp[3][4], pp[4][4], pp[5][4], s1_1[12], c1_1[12]);
    full_adder_1bit fa1_2_5(pp[3][5], pp[4][5], pp[5][5], s1_1[13], c1_1[13]);
    full_adder_1bit fa1_2_6(pp[3][6], pp[4][6], pp[5][6], s1_1[14], c1_1[14]);
    
    // Wallace tree reduction - Second stage
    wire [11:0] s2_1, c2_1;
    full_adder_1bit fa2_1_0(s1_1[0], c1_1[0], 1'b0, s2_1[0], c2_1[0]);
    full_adder_1bit fa2_1_1(s1_1[1], c1_1[1], s1_1[8], s2_1[1], c2_1[1]);
    full_adder_1bit fa2_1_2(s1_1[2], c1_1[2], s1_1[9], s2_1[2], c2_1[2]);
    full_adder_1bit fa2_1_3(s1_1[3], c1_1[3], s1_1[10], s2_1[3], c2_1[3]);
    full_adder_1bit fa2_1_4(s1_1[4], c1_1[4], s1_1[11], s2_1[4], c2_1[4]);
    full_adder_1bit fa2_1_5(s1_1[5], c1_1[5], s1_1[12], s2_1[5], c2_1[5]);
    full_adder_1bit fa2_1_6(s1_1[6], c1_1[6], s1_1[13], s2_1[6], c2_1[6]);
    full_adder_1bit fa2_1_7(s1_1[7], c1_1[7], s1_1[14], s2_1[7], c2_1[7]);
    full_adder_1bit fa2_1_8(pp[6][0], pp[7][0], c1_1[8], s2_1[8], c2_1[8]);
    full_adder_1bit fa2_1_9(pp[6][1], pp[7][1], c1_1[9], s2_1[9], c2_1[9]);
    full_adder_1bit fa2_1_10(pp[6][2], pp[7][2], c1_1[10], s2_1[10], c2_1[10]);
    full_adder_1bit fa2_1_11(pp[6][3], pp[7][3], c1_1[11], s2_1[11], c2_1[11]);
    
    // Final stage - Ripple Carry Adder for remaining bits
    wire [15:0] final_sum, final_carry;
    assign final_sum[0] = s2_1[0];
    assign final_carry[0] = 1'b0;
    
    generate
        for (i = 1; i < 16; i = i + 1) begin : final_adder
            if (i == 1) begin
                assign final_sum[i] = s2_1[i] ^ c2_1[i-1] ^ final_carry[i-1];
                assign final_carry[i] = (s2_1[i] & c2_1[i-1]) | (s2_1[i] & final_carry[i-1]) | (c2_1[i-1] & final_carry[i-1]);
            end
            else if (i < 12) begin
                assign final_sum[i] = s2_1[i] ^ c2_1[i-1] ^ final_carry[i-1];
                assign final_carry[i] = (s2_1[i] & c2_1[i-1]) | (s2_1[i] & final_carry[i-1]) | (c2_1[i-1] & final_carry[i-1]);
            end
            else if (i == 12) begin
                assign final_sum[i] = c2_1[i-1] ^ c1_1[12] ^ final_carry[i-1];
                assign final_carry[i] = (c2_1[i-1] & c1_1[12]) | (c2_1[i-1] & final_carry[i-1]) | (c1_1[12] & final_carry[i-1]);
            end
            else if (i == 13) begin
                assign final_sum[i] = c1_1[13] ^ pp[6][7] ^ final_carry[i-1];
                assign final_carry[i] = (c1_1[13] & pp[6][7]) | (c1_1[13] & final_carry[i-1]) | (pp[6][7] & final_carry[i-1]);
            end
            else if (i == 14) begin
                assign final_sum[i] = c1_1[14] ^ pp[7][7] ^ final_carry[i-1];
                assign final_carry[i] = (c1_1[14] & pp[7][7]) | (c1_1[14] & final_carry[i-1]) | (pp[7][7] & final_carry[i-1]);
            end
            else begin
                assign final_sum[i] = final_carry[i-1];
                assign final_carry[i] = 1'b0;
            end
        end
    endgenerate
    
    // Register result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'b0;
        end else begin
            product <= final_sum;
        end
    end
endmodule

// 1-bit Full Adder
module full_adder_1bit (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule