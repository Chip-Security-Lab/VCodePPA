module MuxSub(input [3:0] x,y, output [3:0] d);
    wire [3:0] y_neg;
    wire [3:0] g0, p0;
    wire [3:0] g1, p1;
    wire [3:0] g2, p2;
    wire [3:0] c;
    
    // Optimized two's complement
    assign y_neg = ~y + 1'b1;
    
    // Optimized initial propagate and generate
    assign g0 = x & y_neg;
    assign p0 = x ^ y_neg;
    
    // Optimized first level prefix computation
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    assign g1[1] = g0[1] | (p0[1] & g0[0]);
    assign p1[1] = p0[1] & p0[0];
    assign g1[2] = g0[2] | (p0[2] & g0[1]);
    assign p1[2] = p0[2] & p0[1];
    assign g1[3] = g0[3] | (p0[3] & g0[2]);
    assign p1[3] = p0[3] & p0[2];
    
    // Optimized second level prefix computation
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    
    // Optimized carry computation
    assign c = {g2[2], g2[1], g2[0], 1'b0};
    
    // Optimized sum computation
    assign d = p0 ^ c;
endmodule