//SystemVerilog
// SystemVerilog
// Top-level module for the 8-bit NOT gate using a parameterized sub-module
module not_gate_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);

    // Instantiate the parameterized 8-bit NOT gate sub-module
    not_gate_vector #(.WIDTH(8)) not_inst (
        .in_vector(A),
        .out_vector(Y)
    );

endmodule

// Parameterized sub-module for a vector of NOT gates
// This module performs bitwise NOT operation on an input vector.
module not_gate_vector #(
    parameter WIDTH = 1 // Width of the input/output vector
) (
    input wire [WIDTH-1:0] in_vector,  // Input vector
    output wire [WIDTH-1:0] out_vector // Output vector
);

    // Perform bitwise NOT operation
    assign out_vector = ~in_vector;

endmodule