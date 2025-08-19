//SystemVerilog
module and_gate_enable (
    input wire [7:0] a,      // 8-bit Input A
    input wire [7:0] b,      // 8-bit Input B
    input wire enable,      // Enable signal
    output reg [15:0] y     // 16-bit Output Y
);

    wire [63:0] partial_products;
    wire [15:0] result;
    
    // Generate partial products
    genvar i, j;
    generate
        for(i = 0; i < 8; i = i + 1) begin: gen_i
            for(j = 0; j < 8; j = j + 1) begin: gen_j
                assign partial_products[i*8+j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda reduction stages
    // Stage 1: Reduce from height 8 to 6
    wire [20:0] s1, c1;
    
    // First reduction level using half adders and full adders
    half_adder ha1_1(partial_products[8], partial_products[1], s1[0], c1[0]);
    half_adder ha1_2(partial_products[16], partial_products[9], s1[1], c1[1]);
    full_adder fa1_1(partial_products[24], partial_products[17], partial_products[2], s1[2], c1[2]);
    half_adder ha1_3(partial_products[32], partial_products[25], s1[3], c1[3]);
    full_adder fa1_2(partial_products[40], partial_products[33], partial_products[18], s1[4], c1[4]);
    full_adder fa1_3(partial_products[48], partial_products[41], partial_products[26], s1[5], c1[5]);
    half_adder ha1_4(partial_products[56], partial_products[49], s1[6], c1[6]);
    
    // Pass through signals
    assign s1[7] = partial_products[0];
    assign s1[8] = partial_products[3];
    assign s1[9] = partial_products[10];
    assign s1[10] = partial_products[19];
    assign s1[11] = partial_products[34];
    assign s1[12] = partial_products[42];
    assign s1[13] = partial_products[50];
    assign s1[14] = partial_products[57];
    assign s1[15] = partial_products[4];
    assign s1[16] = partial_products[11];
    assign s1[17] = partial_products[27];
    assign s1[18] = partial_products[35];
    assign s1[19] = partial_products[43];
    assign s1[20] = partial_products[51];
    
    // Stage 2: Reduce from height 6 to 4
    wire [17:0] s2, c2;
    
    half_adder ha2_1(s1[8], s1[1], s2[0], c2[0]);
    full_adder fa2_1(s1[9], s1[2], c1[0], s2[1], c2[1]);
    full_adder fa2_2(s1[10], s1[3], c1[1], s2[2], c2[2]);
    full_adder fa2_3(s1[11], s1[4], c1[2], s2[3], c2[3]);
    full_adder fa2_4(s1[12], s1[5], c1[3], s2[4], c2[4]);
    full_adder fa2_5(s1[13], s1[6], c1[4], s2[5], c2[5]);
    half_adder ha2_2(s1[14], c1[5], s2[6], c2[6]);
    
    // Pass through signals
    assign s2[7] = s1[0];
    assign s2[8] = s1[7];
    assign s2[9] = s1[15];
    assign s2[10] = s1[16];
    assign s2[11] = s1[17];
    assign s2[12] = s1[18];
    assign s2[13] = s1[19];
    assign s2[14] = s1[20];
    assign s2[15] = partial_products[58];
    assign s2[16] = partial_products[59];
    assign s2[17] = partial_products[63];
    
    // Stage 3: Reduce from height 4 to 3
    wire [15:0] s3, c3;
    
    half_adder ha3_1(s2[9], c2[0], s3[0], c3[0]);
    full_adder fa3_1(s2[10], c2[1], s3[0], s3[1], c3[1]);
    full_adder fa3_2(s2[11], c2[2], s3[1], s3[2], c3[2]);
    full_adder fa3_3(s2[12], c2[3], s3[2], s3[3], c3[3]);
    full_adder fa3_4(s2[13], c2[4], s3[3], s3[4], c3[4]);
    full_adder fa3_5(s2[14], c2[5], s3[4], s3[5], c3[5]);
    full_adder fa3_6(s2[15], c2[6], s3[5], s3[6], c3[6]);
    half_adder ha3_2(s2[16], c1[6], s3[7], c3[7]);
    
    // Pass through signals
    assign s3[8] = s2[7];
    assign s3[9] = s2[8];
    assign s3[10] = s2[0];
    assign s3[11] = s2[1];
    assign s3[12] = s2[2];
    assign s3[13] = s2[3];
    assign s3[14] = s2[4];
    assign s3[15] = s2[17];
    
    // Stage 4: Final addition
    carry_lookahead_adder cla(
        {s3[15:8], s3[7:0]},
        {1'b0, c3[7:0], c2[7:0]},
        1'b0,
        result
    );
    
    // Apply enable signal
    always @(*) begin
        if (enable) begin
            y = result;
        end else begin
            y = 16'b0;
        end
    end
endmodule

// Half Adder module
module half_adder(
    input wire a,
    input wire b,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// Full Adder module
module full_adder(
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// Carry Lookahead Adder for final addition
module carry_lookahead_adder(
    input wire [15:0] a,
    input wire [15:0] b,
    input wire cin,
    output wire [15:0] sum
);
    wire [16:0] carry;
    wire [15:0] p, g;
    
    assign carry[0] = cin;
    
    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    generate
        for(i = 0; i < 16; i = i + 1) begin: gen_carry
            assign carry[i+1] = g[i] | (p[i] & carry[i]);
        end
    endgenerate
    
    generate
        for(i = 0; i < 16; i = i + 1) begin: gen_sum
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule