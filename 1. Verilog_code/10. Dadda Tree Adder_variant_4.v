module manchester_adder (
    input  [3:0] a, b,
    output [3:0] sum
);

    wire [3:0] g, p;
    wire [3:0] c;
    
    // Generate and propagate signals
    assign g = a & b;
    assign p = a ^ b;
    
    // Optimized carry chain
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & g[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    // Sum computation
    assign sum = p ^ {c[2:0], 1'b0};

endmodule