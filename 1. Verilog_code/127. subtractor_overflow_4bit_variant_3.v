module subtractor_overflow_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output overflow
);
    // Internal signals
    wire [3:0] diff_wire;
    wire [3:0] borrow;
    
    // Submodule instances
    subtractor_4bit sub_inst (
        .a(a),
        .b(b),
        .diff(diff_wire),
        .borrow(borrow)
    );
    
    overflow_detector ovf_inst (
        .a(a),
        .b(b),
        .diff(diff_wire),
        .overflow(overflow)
    );
    
    // Output assignment
    assign diff = diff_wire;
endmodule

module subtractor_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output [3:0] borrow
);
    // Generate and propagate signals
    wire [3:0] g = a & ~b;  // Generate
    wire [3:0] p = ~a ^ b;  // Propagate
    
    // Borrow calculation using carry lookahead
    assign borrow[0] = 1'b0;
    assign borrow[1] = g[0] | (p[0] & borrow[0]);
    assign borrow[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & borrow[0]);
    assign borrow[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & borrow[0]);
    
    // Difference calculation
    assign diff = a ^ b ^ {borrow[2:0], 1'b0};
endmodule

module overflow_detector (
    input [3:0] a,
    input [3:0] b,
    input [3:0] diff,
    output overflow
);
    assign overflow = (a[3] & ~b[3] & ~diff[3]) | (~a[3] & b[3] & diff[3]);
endmodule