//SystemVerilog
module selective_bit_matcher #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data, pattern, bit_select,
    output match
);
    // Optimize using Boolean algebra: 
    // (data ^ pattern) & bit_select == 0 
    // can be rewritten as: ~((data ^ pattern) & bit_select) == 1
    // which simplifies to: ~(data ^ pattern) | ~bit_select == 1
    // Using XNOR: (data ~^ pattern) | ~bit_select == 1
    
    wire [WIDTH-1:0] xnor_result = data ~^ pattern;
    wire [WIDTH-1:0] masked_result = xnor_result | ~bit_select;
    
    // Use reduction AND to check if all bits are 1
    assign match = &masked_result;
endmodule