module gray_code_comparator #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] gray_a,
    input [WIDTH-1:0] gray_b,
    output equal,
    output greater, // In gray code context, this requires binary conversion
    output less     // In gray code context, this requires binary conversion
);
    // Direct equality comparison works the same in Gray code
    assign equal = (gray_a == gray_b);
    
    // Convert Gray code to binary for magnitude comparison
    reg [WIDTH-1:0] binary_a, binary_b;
    integer i;
    
    // Gray to binary conversion for a
    always @(*) begin
        binary_a[WIDTH-1] = gray_a[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i - 1) begin
            binary_a[i] = gray_a[i] ^ binary_a[i+1];
        end
    end
    
    // Gray to binary conversion for b
    always @(*) begin
        binary_b[WIDTH-1] = gray_b[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i - 1) begin
            binary_b[i] = gray_b[i] ^ binary_b[i+1];
        end
    end
    
    // Compare converted binary values
    assign greater = (binary_a > binary_b);
    assign less = (binary_a < binary_b);
endmodule
