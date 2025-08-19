//SystemVerilog
module arith_extend (
    input [3:0] operand,
    output [4:0] inc,
    output [4:0] dec
);
    // Instantiate increment operation module
    increment_calc inc_op (
        .data_in(operand),
        .result(inc)
    );
    
    // Instantiate decrement operation module
    decrement_calc dec_op (
        .data_in(operand),
        .result(dec)
    );
endmodule

// Increment calculation module
module increment_calc #(
    parameter WIDTH_IN = 4,
    parameter WIDTH_OUT = 5
)(
    input [WIDTH_IN-1:0] data_in,
    output [WIDTH_OUT-1:0] result
);
    // Perform increment operation with parameterized width
    assign result = data_in + 1'b1;
endmodule

// Decrement calculation module
module decrement_calc #(
    parameter WIDTH_IN = 4,
    parameter WIDTH_OUT = 5
)(
    input [WIDTH_IN-1:0] data_in,
    output [WIDTH_OUT-1:0] result
);
    // Perform decrement operation with parameterized width
    assign result = data_in - 1'b1;
endmodule