//SystemVerilog
// SystemVerilog
// Top level module
module not_gate_10bit_top (
    input wire [9:0] A,
    output wire [9:0] Y
);

    // Internal wire to connect the NOT operation submodule output to the top-level output
    wire [9:0] not_result;

    // Instantiate the submodule responsible for the 10-bit NOT operation
    not_operation_submodule not_op_inst (
        .input_vector(A),
        .output_vector(not_result)
    );

    // Assign the result of the NOT operation to the top-level output
    assign Y = not_result;

endmodule

// Submodule for performing the 10-bit bitwise NOT operation
// This module takes a 10-bit input vector and produces a 10-bit output vector
// where each bit is the logical NOT of the corresponding input bit.
module not_operation_submodule (
    input wire [9:0] input_vector,
    output wire [9:0] output_vector
);

    // Perform the bitwise NOT operation on the input vector
    assign output_vector = ~input_vector;

endmodule