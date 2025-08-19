module han_carlson_adder(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);

    // Generate and propagate signals
    wire [3:0] g, p;
    wire [3:0] carry;
    
    // Stage 0: Generate initial G,P signals
    genvar i;
    generate
        for(i=0; i<4; i=i+1) begin: stage0
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate

    // Stage 1: First level of prefix computation (Han-Carlson)
    wire [3:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    
    genvar j;
    generate
        for(j=1; j<4; j=j+2) begin: stage1
            assign g1[j] = g[j] | (p[j] & g[j-1]);
            assign p1[j] = p[j] & p[j-1];
            if(j+1 < 4) begin
                assign g1[j+1] = g[j+1];
                assign p1[j+1] = p[j+1];
            end
        end
    endgenerate

    // Stage 2: Second level of prefix computation (Han-Carlson)
    wire [3:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    
    genvar k;
    generate
        for(k=2; k<4; k=k+2) begin: stage2
            assign g2[k] = g1[k] | (p1[k] & g1[k-2]);
            assign p2[k] = p1[k] & p1[k-2];
            if(k+1 < 4) begin
                assign g2[k+1] = g1[k+1];
                assign p2[k+1] = p1[k+1];
            end
        end
    endgenerate

    // Final carry computation
    assign carry[0] = cin;
    assign carry[1] = g2[0] | (p2[0] & cin);
    assign carry[2] = g2[1] | (p2[1] & cin);
    assign carry[3] = g2[2] | (p2[2] & cin);
    assign cout = g2[3] | (p2[3] & cin);

    // Sum computation
    assign sum = p ^ {carry[2:0], cin};

endmodule