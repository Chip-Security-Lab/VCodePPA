//SystemVerilog
module gray_code_comparator #(
    parameter WIDTH = 8
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
    wire [WIDTH-1:0] diff;
    wire borrow_out;
    
    // Gray to binary conversion for a
    assign binary_a[WIDTH-1] = gray_a[WIDTH-1];
    genvar j;
    generate
        for (j = WIDTH-2; j >= 0; j = j - 1) begin : gen_gray_to_bin_a
            assign binary_a[j] = gray_a[j] ^ binary_a[j+1];
        end
    endgenerate
    
    // Gray to binary conversion for b
    assign binary_b[WIDTH-1] = gray_b[WIDTH-1];
    generate
        for (j = WIDTH-2; j >= 0; j = j - 1) begin : gen_gray_to_bin_b
            assign binary_b[j] = gray_b[j] ^ binary_b[j+1];
        end
    endgenerate
    
    // Implement binary comparison using two's complement subtraction (a - b)
    // Two's complement of b is ~b + 1
    assign {borrow_out, diff} = {1'b0, binary_a} + {1'b0, ~binary_b} + 9'b1;
    
    // Compare based on subtraction result
    // If diff[WIDTH-1] (sign bit) is 0 and diff is not 0, then a > b
    // If diff[WIDTH-1] (sign bit) is 1, then a < b
    // If diff is 0, then a = b (already handled by equal signal)
    assign greater = (diff != 0) & ~diff[WIDTH-1];
    assign less = diff[WIDTH-1];
endmodule