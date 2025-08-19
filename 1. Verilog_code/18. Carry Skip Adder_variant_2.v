module manchester_carry_chain_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);

    // Generate and propagate signals
    wire [3:0] g = a & b;
    wire [3:0] p = a ^ b;
    
    // Manchester carry chain
    wire [3:0] c;
    wire [3:0] carry_chain;
    
    // Carry chain implementation
    assign carry_chain[0] = g[0] | (p[0] & cin);
    assign carry_chain[1] = g[1] | (p[1] & carry_chain[0]);
    assign carry_chain[2] = g[2] | (p[2] & carry_chain[1]);
    assign carry_chain[3] = g[3] | (p[3] & carry_chain[2]);
    
    // Final carry out
    assign cout = carry_chain[3];
    
    // Sum calculation
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ carry_chain[0];
    assign sum[2] = p[2] ^ carry_chain[1];
    assign sum[3] = p[3] ^ carry_chain[2];

endmodule