//SystemVerilog
module async_comparator_active_low(
    input [7:0] operand_1,
    input [7:0] operand_2,
    output equal_n,      // Active low equal indicator
    output greater_n,    // Active low greater than indicator  
    output lesser_n      // Active low less than indicator
);
    wire [7:0] diff = operand_1 - operand_2;

    // Optimized combinational logic with active low outputs
    assign equal_n   = ~(diff == 8'b0);
    assign greater_n = ~(diff[7]); // MSB indicates if operand_1 > operand_2
    assign lesser_n  = diff[7];     // MSB indicates if operand_1 < operand_2

endmodule