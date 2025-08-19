//SystemVerilog

module async_comparator_active_low(
    input [7:0] operand_1,
    input [7:0] operand_2,
    output equal_n,
    output greater_n,
    output lesser_n
);
    wire equal_n_internal;
    wire greater_n_internal;
    wire lesser_n_internal;

    // Instantiate submodules
    comparator_equal equal_module (
        .operand_1(operand_1),
        .operand_2(operand_2),
        .equal_n(equal_n_internal)
    );

    comparator_greater greater_module (
        .operand_1(operand_1),
        .operand_2(operand_2),
        .greater_n(greater_n_internal)
    );

    comparator_lesser lesser_module (
        .operand_1(operand_1),
        .operand_2(operand_2),
        .lesser_n(lesser_n_internal)
    );

    // Connect internal signals to outputs
    assign equal_n = equal_n_internal;
    assign greater_n = greater_n_internal;
    assign lesser_n = lesser_n_internal;

endmodule

module comparator_equal(
    input [7:0] operand_1,
    input [7:0] operand_2,
    output equal_n
);
    // Direct active-low comparison logic for equality
    assign equal_n = |(operand_1 ^ operand_2);
endmodule

module comparator_greater(
    input [7:0] operand_1,
    input [7:0] operand_2,
    output greater_n
);
    // Direct active-low comparison logic for greater than
    assign greater_n = ~(&(operand_1[7:0] & ~operand_2[7:0]) | 
                        (operand_1[7] & ~operand_2[7]) |
                        (operand_1[6] & ~operand_2[6] & operand_1[7:7] == operand_2[7:7]) |
                        (operand_1[5] & ~operand_2[5] & operand_1[7:6] == operand_2[7:6]) |
                        (operand_1[4] & ~operand_2[4] & operand_1[7:5] == operand_2[7:5]) |
                        (operand_1[3] & ~operand_2[3] & operand_1[7:4] == operand_2[7:4]) |
                        (operand_1[2] & ~operand_2[2] & operand_1[7:3] == operand_2[7:3]) |
                        (operand_1[1] & ~operand_2[1] & operand_1[7:2] == operand_2[7:2]) |
                        (operand_1[0] & ~operand_2[0] & operand_1[7:1] == operand_2[7:1]));
endmodule

module comparator_lesser(
    input [7:0] operand_1,
    input [7:0] operand_2,
    output lesser_n
);
    // Direct active-low comparison logic for lesser than
    assign lesser_n = ~(&(~operand_1[7:0] & operand_2[7:0]) | 
                        (~operand_1[7] & operand_2[7]) |
                        (~operand_1[6] & operand_2[6] & operand_1[7:7] == operand_2[7:7]) |
                        (~operand_1[5] & operand_2[5] & operand_1[7:6] == operand_2[7:6]) |
                        (~operand_1[4] & operand_2[4] & operand_1[7:5] == operand_2[7:5]) |
                        (~operand_1[3] & operand_2[3] & operand_1[7:4] == operand_2[7:4]) |
                        (~operand_1[2] & operand_2[2] & operand_1[7:3] == operand_2[7:3]) |
                        (~operand_1[1] & operand_2[1] & operand_1[7:2] == operand_2[7:2]) |
                        (~operand_1[0] & operand_2[0] & operand_1[7:1] == operand_2[7:1]));
endmodule