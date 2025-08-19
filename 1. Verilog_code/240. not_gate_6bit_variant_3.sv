//SystemVerilog
// SystemVerilog
// Top-level module for a 6-bit NOT gate using a parameterized sub-module
module not_gate_6bit (
    input wire [5:0] A,
    output wire [5:0] Y
);

    // Instantiate the parameterized NOT gate module
    // Performs bitwise NOT operation on the entire 6-bit vector
    not_gate_param #(
        .DATA_WIDTH(6)
    ) not_inst (
        .in_data(A),
        .out_data(Y)
    );

endmodule

// Parameterized NOT gate sub-module
// Performs logical NOT operation on a vector of specified width
module not_gate_param #(
    parameter DATA_WIDTH = 1
) (
    input wire [DATA_WIDTH-1:0] in_data,
    output wire [DATA_WIDTH-1:0] out_data
);

    // Assign the bitwise NOT of the input to the output
    assign out_data = ~in_data;

endmodule