module brent_kung_adder(
    input [4:0] a, b,
    input cin,
    output [4:0] sum,
    output cout
);

    // Generate and propagate signals
    wire [4:0] g, p;
    wire [4:0] carry;
    
    // First level - Generate and Propagate
    genvar i;
    generate
        for(i = 0; i < 5; i = i + 1) begin: gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate

    // Second level - Group Generate and Propagate
    wire [2:0] g2, p2;
    assign g2[0] = g[1] | (p[1] & g[0]);
    assign p2[0] = p[1] & p[0];
    
    assign g2[1] = g[3] | (p[3] & g[2]);
    assign p2[1] = p[3] & p[2];
    
    assign g2[2] = g[4] | (p[4] & g[3]);
    assign p2[2] = p[4] & p[3];

    // Third level - Final Group Generate
    wire g3;
    assign g3 = g2[1] | (p2[1] & g2[0]);

    // Carry computation
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & cin);
    assign carry[2] = g2[0] | (p2[0] & cin);
    assign carry[3] = g[1] | (p[1] & carry[1]);
    assign carry[4] = g3 | (p2[0] & cin);
    assign cout = carry[4];

    // Sum computation
    genvar j;
    generate
        for(j = 0; j < 5; j = j + 1) begin: sum_gen
            assign sum[j] = p[j] ^ carry[j];
        end
    endgenerate

endmodule