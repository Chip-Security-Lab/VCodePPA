module manchester_adder(
    input [4:0] a, b,
    input cin,
    output [4:0] sum,
    output cout
);

    wire [4:0] g, p;
    wire [4:0] c;
    wire [4:0] carry;
    
    // Generate and propagate signals
    assign g[0] = a[0] & b[0];
    assign p[0] = a[0] ^ b[0];
    
    assign g[1] = a[1] & b[1];
    assign p[1] = a[1] ^ b[1];
    
    assign g[2] = a[2] & b[2];
    assign p[2] = a[2] ^ b[2];
    
    assign g[3] = a[3] & b[3];
    assign p[3] = a[3] ^ b[3];
    
    assign g[4] = a[4] & b[4];
    assign p[4] = a[4] ^ b[4];
    
    // Manchester carry chain
    assign c[0] = cin;
    assign carry[0] = g[0] | (p[0] & c[0]);
    
    assign carry[1] = g[1] | (p[1] & carry[0]);
    assign carry[2] = g[2] | (p[2] & carry[1]);
    assign carry[3] = g[3] | (p[3] & carry[2]);
    assign carry[4] = g[4] | (p[4] & carry[3]);
    
    // Sum calculation
    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];
    assign sum[4] = p[4] ^ carry[4];
    
    assign cout = carry[4];

endmodule