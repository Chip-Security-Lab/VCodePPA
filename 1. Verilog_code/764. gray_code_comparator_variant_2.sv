//SystemVerilog
module gray_code_comparator #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] gray_a,
    input [WIDTH-1:0] gray_b,
    output equal,
    output greater,
    output less
);
    // Direct equality comparison works the same in Gray code
    assign equal = (gray_a == gray_b);
    
    // Convert Gray code to binary for magnitude comparison
    wire [WIDTH-1:0] binary_a, binary_b;
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // Gray to binary conversion for a
    assign binary_a[WIDTH-1] = gray_a[WIDTH-1];
    genvar j;
    generate
        for (j = WIDTH-2; j >= 0; j = j - 1) begin : gen_bin_a
            assign binary_a[j] = gray_a[j] ^ binary_a[j+1];
        end
    endgenerate
    
    // Gray to binary conversion for b
    assign binary_b[WIDTH-1] = gray_b[WIDTH-1];
    genvar k;
    generate
        for (k = WIDTH-2; k >= 0; k = k - 1) begin : gen_bin_b
            assign binary_b[k] = gray_b[k] ^ binary_b[k+1];
        end
    endgenerate
    
    // Implement look-ahead borrow subtractor for comparison
    assign borrow[0] = 1'b0; // No initial borrow
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor
            // Generate (G) term: borrow generated when a=0, b=1
            wire gen_borrow = ~binary_a[i] & binary_b[i];
            
            // Propagate (P) term: borrow propagated when a=0, b=0 or a=1, b=1
            wire prop_borrow = ~(binary_a[i] ^ binary_b[i]);
            
            // Borrow calculation with look-ahead logic
            assign borrow[i+1] = gen_borrow | (prop_borrow & borrow[i]);
            
            // Difference calculation
            assign diff[i] = binary_a[i] ^ binary_b[i] ^ borrow[i];
        end
    endgenerate
    
    // Final comparison results based on borrow and difference
    assign greater = ~borrow[WIDTH] & (|diff);
    assign less = borrow[WIDTH];
endmodule