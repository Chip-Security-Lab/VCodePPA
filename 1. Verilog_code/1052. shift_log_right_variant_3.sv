//SystemVerilog

//-----------------------------------------------------------------------------
// Submodule: SubtrahendGenerator
// Function: Generates the two's complement of (1 << SHIFT) for subtraction
//-----------------------------------------------------------------------------
module SubtrahendGenerator #(parameter WIDTH=8, SHIFT=2) (
    output [WIDTH-1:0] two_comp_subtrahend
);
    wire [WIDTH-1:0] subtrahend;
    assign subtrahend = {{(WIDTH-SHIFT){1'b0}}, {1'b1}, {(SHIFT-1){1'b0}}};
    assign two_comp_subtrahend = ~subtrahend + {{(WIDTH-1){1'b0}}, 1'b1};
endmodule

//-----------------------------------------------------------------------------
// Submodule: AdderUnit
// Function: Performs binary addition of two WIDTH-bit numbers
//-----------------------------------------------------------------------------
module AdderUnit #(parameter WIDTH=8) (
    input  [WIDTH-1:0] operand_a,
    input  [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] sum,
    output             carry_out
);
    assign {carry_out, sum} = {1'b0, operand_a} + {1'b0, operand_b};
endmodule

//-----------------------------------------------------------------------------
// Top-Level Module: shift_log_right
// Function: Computes logical right shift using binary subtraction
//-----------------------------------------------------------------------------
module shift_log_right #(parameter WIDTH=8, SHIFT=2) (
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    // Internal signal declarations
    wire [WIDTH-1:0] two_comp_subtrahend;
    wire [WIDTH-1:0] sum_result;
    wire             carry_out;

    // Subtrahend generation
    SubtrahendGenerator #(.WIDTH(WIDTH), .SHIFT(SHIFT)) u_subtrahend_gen (
        .two_comp_subtrahend(two_comp_subtrahend)
    );

    // Adder unit
    AdderUnit #(.WIDTH(WIDTH)) u_adder (
        .operand_a(data_in),
        .operand_b(two_comp_subtrahend),
        .sum(sum_result),
        .carry_out(carry_out)
    );

    // Output assignment
    assign data_out = sum_result;

endmodule