module mult_4bit(
    input [3:0] a, b,
    output [7:0] prod
);

    // Partial products
    wire [3:0] pp0, pp1, pp2, pp3;
    
    // Generate partial products
    assign pp0 = a & {4{b[0]}};
    assign pp1 = a & {4{b[1]}};
    assign pp2 = a & {4{b[2]}};
    assign pp3 = a & {4{b[3]}};
    
    // Stage 1: First level of Wallace tree
    wire [4:0] sum1, carry1;
    wire [3:0] sum2, carry2;
    
    // First CSA
    full_adder fa1_0(pp0[0], pp1[0], pp2[0], sum1[0], carry1[0]);
    full_adder fa1_1(pp0[1], pp1[1], pp2[1], sum1[1], carry1[1]);
    full_adder fa1_2(pp0[2], pp1[2], pp2[2], sum1[2], carry1[2]);
    full_adder fa1_3(pp0[3], pp1[3], pp2[3], sum1[3], carry1[3]);
    assign sum1[4] = pp3[3];
    
    // Second CSA
    full_adder fa2_0(pp3[0], sum1[1], carry1[0], sum2[0], carry2[0]);
    full_adder fa2_1(pp3[1], sum1[2], carry1[1], sum2[1], carry2[1]);
    full_adder fa2_2(pp3[2], sum1[3], carry1[2], sum2[2], carry2[2]);
    full_adder fa2_3(pp3[3], sum1[4], carry1[3], sum2[3], carry2[3]);
    
    // Final addition using carry lookahead adder
    wire [7:0] sum_final, carry_final;
    assign sum_final = {sum2, sum1[0]};
    assign carry_final = {carry2, carry1[0], 1'b0};
    
    // Carry lookahead adder implementation
    wire [7:0] g, p, c;
    wire [7:0] sum_out;
    
    // Generate and propagate signals
    assign g = sum_final & carry_final;
    assign p = sum_final ^ carry_final;
    
    // Carry lookahead logic
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum calculation
    assign sum_out = p ^ c;
    assign prod = sum_out;

endmodule

// Full adder module
module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule