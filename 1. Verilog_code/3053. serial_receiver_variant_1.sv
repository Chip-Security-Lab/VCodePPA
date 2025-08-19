//SystemVerilog
module baugh_wooley_multiplier(
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    // Partial products generation
    wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    wire [7:0] pp0_ext, pp1_ext, pp2_ext, pp3_ext, pp4_ext, pp5_ext, pp6_ext, pp7_ext;
    
    // Generate partial products with sign extension
    assign pp0 = {8{a[0]}} & b;
    assign pp1 = {8{a[1]}} & b;
    assign pp2 = {8{a[2]}} & b;
    assign pp3 = {8{a[3]}} & b;
    assign pp4 = {8{a[4]}} & b;
    assign pp5 = {8{a[5]}} & b;
    assign pp6 = {8{a[6]}} & b;
    assign pp7 = {8{a[7]}} & b;
    
    // Sign extension for partial products
    assign pp0_ext = {1'b0, pp0};
    assign pp1_ext = {1'b0, pp1};
    assign pp2_ext = {1'b0, pp2};
    assign pp3_ext = {1'b0, pp3};
    assign pp4_ext = {1'b0, pp4};
    assign pp5_ext = {1'b0, pp5};
    assign pp6_ext = {1'b0, pp6};
    assign pp7_ext = {1'b0, pp7};
    
    // Wallace tree reduction
    wire [8:0] sum1, carry1;
    wire [8:0] sum2, carry2;
    wire [8:0] sum3, carry3;
    wire [8:0] sum4, carry4;
    
    // First level of reduction using carry-skip adders
    carry_skip_adder_9bit csa1(
        .a(pp0_ext),
        .b(pp1_ext << 1),
        .sum(sum1),
        .carry(carry1)
    );
    
    carry_skip_adder_9bit csa2(
        .a(pp2_ext),
        .b(pp3_ext << 1),
        .sum(sum2),
        .carry(carry2)
    );
    
    carry_skip_adder_9bit csa3(
        .a(pp4_ext),
        .b(pp5_ext << 1),
        .sum(sum3),
        .carry(carry3)
    );
    
    carry_skip_adder_9bit csa4(
        .a(pp6_ext),
        .b(pp7_ext << 1),
        .sum(sum4),
        .carry(carry4)
    );
    
    // Second level of reduction
    wire [9:0] sum5, carry5;
    wire [9:0] sum6, carry6;
    
    carry_skip_adder_10bit csa5(
        .a({1'b0, sum1}),
        .b({1'b0, sum2}),
        .c({carry1, 1'b0}),
        .d({carry2, 1'b0}),
        .sum(sum5),
        .carry(carry5)
    );
    
    carry_skip_adder_10bit csa6(
        .a({1'b0, sum3}),
        .b({1'b0, sum4}),
        .c({carry3, 1'b0}),
        .d({carry4, 1'b0}),
        .sum(sum6),
        .carry(carry6)
    );
    
    // Final addition
    wire [10:0] final_sum, final_carry;
    
    carry_skip_adder_11bit csa_final(
        .a({1'b0, sum5}),
        .b({1'b0, sum6}),
        .c({carry5, 1'b0}),
        .d({carry6, 1'b0}),
        .sum(final_sum),
        .carry(final_carry)
    );
    
    // Output assignment
    assign product = {final_carry, final_sum};
    
endmodule

// 9-bit carry-skip adder
module carry_skip_adder_9bit(
    input wire [8:0] a,
    input wire [8:0] b,
    output wire [8:0] sum,
    output wire [8:0] carry
);
    wire [8:0] p, g;
    wire [2:0] block_carry;
    
    // Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Block carry generation
    assign block_carry[0] = g[0] | (p[0] & g[1]) | (p[0] & p[1] & g[2]);
    assign block_carry[1] = g[3] | (p[3] & g[4]) | (p[3] & p[4] & g[5]);
    assign block_carry[2] = g[6] | (p[6] & g[7]) | (p[6] & p[7] & g[8]);
    
    // Sum generation
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ g[0];
    assign sum[2] = p[2] ^ block_carry[0];
    assign sum[3] = p[3];
    assign sum[4] = p[4] ^ g[3];
    assign sum[5] = p[5] ^ block_carry[1];
    assign sum[6] = p[6];
    assign sum[7] = p[7] ^ g[6];
    assign sum[8] = p[8] ^ block_carry[2];
    
    // Carry generation
    assign carry[0] = g[0];
    assign carry[1] = block_carry[0];
    assign carry[2] = block_carry[0];
    assign carry[3] = g[3];
    assign carry[4] = block_carry[1];
    assign carry[5] = block_carry[1];
    assign carry[6] = g[6];
    assign carry[7] = block_carry[2];
    assign carry[8] = block_carry[2];
endmodule

// 10-bit carry-skip adder
module carry_skip_adder_10bit(
    input wire [9:0] a,
    input wire [9:0] b,
    input wire [9:0] c,
    input wire [9:0] d,
    output wire [9:0] sum,
    output wire [9:0] carry
);
    wire [9:0] temp_sum1, temp_carry1;
    wire [9:0] temp_sum2, temp_carry2;
    
    carry_skip_adder_9bit csa1(
        .a(a),
        .b(b),
        .sum(temp_sum1),
        .carry(temp_carry1)
    );
    
    carry_skip_adder_9bit csa2(
        .a(c),
        .b(d),
        .sum(temp_sum2),
        .carry(temp_carry2)
    );
    
    carry_skip_adder_9bit csa3(
        .a(temp_sum1),
        .b(temp_sum2),
        .sum(sum),
        .carry(carry)
    );
endmodule

// 11-bit carry-skip adder
module carry_skip_adder_11bit(
    input wire [10:0] a,
    input wire [10:0] b,
    input wire [10:0] c,
    input wire [10:0] d,
    output wire [10:0] sum,
    output wire [10:0] carry
);
    wire [10:0] temp_sum1, temp_carry1;
    wire [10:0] temp_sum2, temp_carry2;
    
    carry_skip_adder_9bit csa1(
        .a(a[8:0]),
        .b(b[8:0]),
        .sum(temp_sum1[8:0]),
        .carry(temp_carry1[8:0])
    );
    
    carry_skip_adder_9bit csa2(
        .a(c[8:0]),
        .b(d[8:0]),
        .sum(temp_sum2[8:0]),
        .carry(temp_carry2[8:0])
    );
    
    carry_skip_adder_9bit csa3(
        .a(temp_sum1[8:0]),
        .b(temp_sum2[8:0]),
        .sum(sum[8:0]),
        .carry(carry[8:0])
    );
    
    // Handle remaining bits
    assign temp_sum1[10:9] = a[10:9] ^ b[10:9];
    assign temp_sum2[10:9] = c[10:9] ^ d[10:9];
    assign sum[10:9] = temp_sum1[10:9] ^ temp_sum2[10:9];
    assign carry[10:9] = (a[10:9] & b[10:9]) | (c[10:9] & d[10:9]);
endmodule