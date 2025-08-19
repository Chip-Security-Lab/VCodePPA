//SystemVerilog
module async_comparator_active_low(
    input [7:0] operand_1,
    input [7:0] operand_2,
    output equal_n,      // Active low equal indicator
    output greater_n,    // Active low greater than indicator  
    output lesser_n      // Active low less than indicator
);
    // Internal signals for comparison results (active high)
    wire equal;
    wire greater;
    wire lesser;
    
    // Instantiate comparison logic module
    comparison_logic comp_logic (
        .operand_1(operand_1),
        .operand_2(operand_2),
        .equal(equal),
        .greater(greater),
        .lesser(lesser)
    );
    
    // Instantiate output polarity converter
    output_inverter out_inv (
        .equal_in(equal),
        .greater_in(greater),
        .lesser_in(lesser),
        .equal_n(equal_n),
        .greater_n(greater_n),
        .lesser_n(lesser_n)
    );
endmodule

module comparison_logic (
    input [7:0] operand_1,
    input [7:0] operand_2,
    output equal,        // Active high equal indicator
    output greater,      // Active high greater than indicator
    output lesser        // Active high less than indicator
);
    // Parameterizable comparison module (active high outputs)
    assign equal   = (operand_1 == operand_2);
    assign greater = (operand_1 > operand_2);
    assign lesser  = (operand_1 < operand_2);
endmodule

module output_inverter (
    input equal_in,
    input greater_in,
    input lesser_in,
    output equal_n,      // Active low equal indicator
    output greater_n,    // Active low greater than indicator
    output lesser_n      // Active low less than indicator
);
    // Convert active high to active low signals
    assign equal_n   = ~equal_in;
    assign greater_n = ~greater_in;
    assign lesser_n  = ~lesser_in;
endmodule