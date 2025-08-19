//SystemVerilog
// Top level module - 4-bit subtractor using borrow method
module subtractor_4bit (
    input wire [3:0] a,  // 4-bit minuend
    input wire [3:0] b,  // 4-bit subtrahend
    output wire [3:0] diff,  // 4-bit difference
    output wire borrow_out  // Output borrow
);
    // Internal borrow signals
    wire [4:0] borrow;
    
    // Initialize the first borrow to 0
    assign borrow[0] = 1'b0;
    
    // Instantiate four 1-bit full subtractors
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_subtractor
            full_subtractor fs (
                .a(a[i]),
                .b(b[i]),
                .borrow_in(borrow[i]),
                .diff(diff[i]),
                .borrow_out(borrow[i+1])
            );
        end
    endgenerate
    
    // Final borrow out
    assign borrow_out = borrow[4];
endmodule

// 1-bit full subtractor using borrow method
module full_subtractor (
    input wire a,         // Minuend bit
    input wire b,         // Subtrahend bit
    input wire borrow_in, // Input borrow
    output wire diff,     // Difference bit
    output wire borrow_out // Output borrow
);
    // Difference: a XOR b XOR borrow_in
    assign diff = a ^ b ^ borrow_in;
    
    // Borrow out: (!a & b) | (!a & borrow_in) | (b & borrow_in)
    assign borrow_out = (~a & b) | (~a & borrow_in) | (b & borrow_in);
endmodule