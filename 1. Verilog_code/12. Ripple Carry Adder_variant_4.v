module manchester_adder(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);

    // Generate and propagate signals
    wire [3:0] g, p;
    wire [3:0] carry;
    
    // Generate and propagate computation
    assign g = a & b;
    assign p = a ^ b;
    
    // Manchester carry chain
    wire [3:0] carry_chain;
    assign carry_chain[0] = g[0] | (p[0] & cin);
    assign carry_chain[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign carry_chain[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign carry_chain[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    
    // Sum computation
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ carry_chain[0];
    assign sum[2] = p[2] ^ carry_chain[1];
    assign sum[3] = p[3] ^ carry_chain[2];
    assign cout = carry_chain[3];

endmodule