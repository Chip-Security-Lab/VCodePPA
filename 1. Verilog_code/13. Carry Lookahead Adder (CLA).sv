module cla_adder(
    input [3:0] a,b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] g = a & b;
    wire [3:0] p = a | b;
    wire [4:0] c;
    
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & (g[0] | (p[0] & c[0])));
    assign c[3] = g[2] | (p[2] & (g[1] | (p[1] & (g[0] | (p[0] & c[0])))));
    assign c[4] = g[3] | (p[3] & (g[2] | (p[2] & (g[1] | (p[1] & (g[0] | (p[0] & c[0])))))));
    
    assign sum = a ^ b ^ c[3:0];
    assign cout = c[4];
endmodule