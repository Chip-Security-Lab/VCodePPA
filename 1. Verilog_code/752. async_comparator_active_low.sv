module async_comparator_active_low(
    input [7:0] operand_1,
    input [7:0] operand_2,
    output equal_n,      // Active low equal indicator
    output greater_n,    // Active low greater than indicator  
    output lesser_n      // Active low less than indicator
);
    // Combinational (asynchronous) logic with active low outputs
    assign equal_n   = ~(operand_1 == operand_2);
    assign greater_n = ~(operand_1 > operand_2);
    assign lesser_n  = ~(operand_1 < operand_2);
endmodule