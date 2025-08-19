//SystemVerilog
module Multiplier4(
    input [3:0] a, b,
    output [7:0] result
);
    wire [7:0] partial_products [3:0];
    wire [7:0] sum1, sum2;
    
    // Generate partial products with improved readability
    genvar i;
    generate
        for(i=0; i<4; i=i+1) begin
            wire [7:0] shifted_a;
            assign shifted_a = a << i;
            assign partial_products[i] = b[i] ? shifted_a : 8'b0;
        end
    endgenerate
    
    // 带状进位加法器实现
    wire [7:0] g1, p1, g2, p2;
    wire [7:0] c;
    wire [7:0] carry_terms [7:0];
    
    // 第一级分组
    assign g1 = partial_products[0] & partial_products[1];
    assign p1 = partial_products[0] ^ partial_products[1];
    assign g2 = partial_products[2] & partial_products[3];
    assign p2 = partial_products[2] ^ partial_products[3];
    
    // 第二级进位计算
    assign c[0] = 1'b0;
    
    // 带状进位加法器的进位计算
    assign carry_terms[0] = g1[0];
    assign carry_terms[1] = p1[1] & g1[0];
    assign carry_terms[2] = p1[2] & g1[1];
    assign carry_terms[3] = p1[3] & g1[2];
    assign carry_terms[4] = p1[4] & g1[3];
    assign carry_terms[5] = p1[5] & g1[4];
    assign carry_terms[6] = p1[6] & g1[5];
    assign carry_terms[7] = p1[7] & g1[6];
    
    // 带状进位链
    assign c[1] = carry_terms[0];
    assign c[2] = g1[1] | carry_terms[1];
    assign c[3] = g1[2] | carry_terms[2] | (p1[2] & carry_terms[1]);
    assign c[4] = g1[3] | carry_terms[3] | (p1[3] & carry_terms[2]) | (p1[3] & p1[2] & carry_terms[1]);
    assign c[5] = g1[4] | carry_terms[4] | (p1[4] & carry_terms[3]) | (p1[4] & p1[3] & carry_terms[2]) | (p1[4] & p1[3] & p1[2] & carry_terms[1]);
    assign c[6] = g1[5] | carry_terms[5] | (p1[5] & carry_terms[4]) | (p1[5] & p1[4] & carry_terms[3]) | (p1[5] & p1[4] & p1[3] & carry_terms[2]) | (p1[5] & p1[4] & p1[3] & p1[2] & carry_terms[1]);
    assign c[7] = g1[6] | carry_terms[6] | (p1[6] & carry_terms[5]) | (p1[6] & p1[5] & carry_terms[4]) | (p1[6] & p1[5] & p1[4] & carry_terms[3]) | (p1[6] & p1[5] & p1[4] & p1[3] & carry_terms[2]) | (p1[6] & p1[5] & p1[4] & p1[3] & p1[2] & carry_terms[1]);
    
    // 最终和的计算
    wire [7:0] carry_in;
    assign carry_in = {c[6:0], 1'b0};
    assign sum1 = p1 ^ carry_in;
    assign sum2 = p2 ^ {g2[6:0], 1'b0};
    assign result = sum1 + sum2;
endmodule