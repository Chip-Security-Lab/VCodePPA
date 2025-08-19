//SystemVerilog
// SystemVerilog
// Top level module for a 6-bit NOT gate, using a parameterized submodule

module not_gate_6bit (
    input wire [5:0] A,
    output wire [5:0] Y
);

    // Instantiate a parameterized NOT gate module for the entire width
    not_gate_generic #(
        .WIDTH(6) // Specify the width for this instance
    ) not_gate_inst (
        .in_data(A),
        .out_data(Y)
    );

endmodule

// Parameterized submodule for a generic width NOT gate
module not_gate_generic #(
    parameter WIDTH = 1 // Default width is 1
) (
    input wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);

    // Perform bitwise NOT operation on the input data
    assign out_data = ~in_data;

endmodule