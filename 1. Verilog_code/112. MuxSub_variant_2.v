module MuxSub(input [3:0] x, y, output [3:0] d);
    wire [3:0] y_comp = ~y + 1;
    
    // Simplified carry-lookahead adder implementation
    wire [3:0] p, g;
    wire [3:0] c;
    
    // Generate and Propagate
    assign p = x ^ y_comp;
    assign g = x & y_comp;
    
    // Carry computation using simplified lookahead
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g[1] | (p[1] & g[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    
    // Sum computation
    assign d = p ^ {c[2:0], 1'b0};
endmodule