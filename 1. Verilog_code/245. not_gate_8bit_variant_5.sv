//SystemVerilog
// SystemVerilog

// Top level module for 8-bit NOT gate
// This module provides an 8-bit NOT gate functionality by instantiating
// a parameterized NOT gate submodule.
module not_gate_8bit (
    input wire [7:0] A, // 8-bit input
    output wire [7:0] Y  // 8-bit output (inverted input)
);

    // Instantiate the parameterized NOT gate submodule
    // The parameter WIDTH is set to 8 to handle 8 bits.
    not_gate_parameterized #(.WIDTH(8))
    not_inst (
        .A(A), // Connect the 8-bit input
        .Y(Y)  // Connect the 8-bit output
    );

endmodule

// Parameterized submodule for an N-bit NOT gate
// This module performs a bitwise NOT operation on an N-bit input.
// The width of the input and output is determined by the parameter WIDTH.
module not_gate_parameterized #(
    parameter WIDTH = 1 // Default width is 1 bit
) (
    input wire [WIDTH-1:0] A, // N-bit input
    output wire [WIDTH-1:0] Y  // N-bit output (inverted input)
);

    // Perform the bitwise NOT operation on the entire vector
    assign Y = ~A;

endmodule