module hybrid_adder(
    input [7:0] a, b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [3:0] sum_low, sum_high;
    wire carry_mid;
    
    cla_adder low(a[3:0], b[3:0], cin, sum_low, carry_mid);
    carry_select_adder high(a[7:4], b[7:4], carry_mid, sum_high, cout);
    
    assign sum = {sum_high, sum_low};
endmodule

module ripple_carry_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [4:0] c;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : ripple
            full_adder fa(
                .a(a[i]),
                .b(b[i]),
                .cin(c[i]),
                .sum(sum[i]),
                .cout(c[i+1])
            );
        end
    endgenerate
    
    assign cout = c[4];
endmodule

module carry_select_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] sum0, sum1;
    wire cout0, cout1;
    
    ripple_carry_adder rca0(a, b, 1'b0, sum0, cout0);
    ripple_carry_adder rca1(a, b, 1'b1, sum1, cout1);
    
    assign sum = cin ? sum1 : sum0;
    assign cout = cin ? cout1 : cout0;
endmodule

module full_adder(
    input a, b, cin,
    output sum, cout
);
    wire ab, ac, bc;
    
    assign ab = a & b;
    assign ac = a & cin;
    assign bc = b & cin;
    assign sum = a ^ b ^ cin;
    assign cout = ab | ac | bc;
endmodule

module cla_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g;
    wire [4:0] c;
    wire [3:0] pg;
    
    assign p = a ^ b;
    assign g = a & b;
    
    assign c[0] = cin;
    assign pg[0] = p[0] & c[0];
    assign c[1] = g[0] | pg[0];
    
    assign pg[1] = p[1] & g[0];
    assign c[2] = g[1] | pg[1] | (p[1] & pg[0]);
    
    assign pg[2] = p[2] & g[1];
    assign c[3] = g[2] | pg[2] | (p[2] & pg[1]) | (p[2] & p[1] & pg[0]);
    
    assign pg[3] = p[3] & g[2];
    assign c[4] = g[3] | pg[3] | (p[3] & pg[2]) | (p[3] & p[2] & pg[1]) | (p[3] & p[2] & p[1] & pg[0]);
    
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule