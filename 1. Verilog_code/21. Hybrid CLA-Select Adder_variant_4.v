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
    
    full_adder fa0(
        .a(a[0]),
        .b(b[0]),
        .cin(c[0]),
        .sum(sum[0]),
        .cout(c[1])
    );
    
    full_adder fa1(
        .a(a[1]),
        .b(b[1]),
        .cin(c[1]),
        .sum(sum[1]),
        .cout(c[2])
    );
    
    full_adder fa2(
        .a(a[2]),
        .b(b[2]),
        .cin(c[2]),
        .sum(sum[2]),
        .cout(c[3])
    );
    
    full_adder fa3(
        .a(a[3]),
        .b(b[3]),
        .cin(c[3]),
        .sum(sum[3]),
        .cout(c[4])
    );
    
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
    wire p, g;
    
    assign p = a ^ b;
    assign g = a & b;
    assign sum = p ^ cin;
    assign cout = g | (p & cin);
endmodule

module cla_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g;
    wire [4:0] c;
    
    assign p = a ^ b;
    assign g = a & b;
    
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule