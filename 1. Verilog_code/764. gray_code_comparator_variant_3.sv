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
    // Direct equality check - efficient and unchanged
    assign equal = (gray_a == gray_b);
    
    // Optimized Gray to binary conversion
    wire [WIDTH-1:0] binary_a, binary_b;
    
    // Parallel XOR-based conversion for better timing
    assign binary_a[WIDTH-1] = gray_a[WIDTH-1];
    assign binary_b[WIDTH-1] = gray_b[WIDTH-1];
    
    genvar g;
    generate
        for (g = WIDTH-2; g >= 0; g = g - 1) begin : gray_to_bin_conversion
            assign binary_a[g] = ^gray_a[WIDTH-1:g];
            assign binary_b[g] = ^gray_b[WIDTH-1:g];
        end
    endgenerate
    
    // Optimized comparison logic - using priority comparison
    // Starting from MSB for earlier termination
    reg greater_reg, less_reg;
    integer i;
    
    always @(*) begin
        greater_reg = 1'b0;
        less_reg = 1'b0;
        
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (binary_a[i] && !binary_b[i] && !greater_reg && !less_reg) begin
                greater_reg = 1'b1;
            end else if (!binary_a[i] && binary_b[i] && !greater_reg && !less_reg) begin
                less_reg = 1'b1;
            end
        end
    end
    
    assign greater = greater_reg;
    assign less = less_reg;
endmodule