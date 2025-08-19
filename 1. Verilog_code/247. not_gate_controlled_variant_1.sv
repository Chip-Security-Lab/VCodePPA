//SystemVerilog
// SystemVerilog
// Top-level module for controlled negation
module not_gate_controlled #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] A,
    input wire control,
    output wire [WIDTH-1:0] Y
);

    // Internal signal for the two's complement result
    wire [WIDTH-1:0] two_complement_A_int;

    // Instantiate the two's complement submodule
    two_complement_calculator #(
        .WIDTH(WIDTH)
    ) u_two_complement_calculator (
        .data_in(A),
        .data_out(two_complement_A_int)
    );

    // Instantiate the multiplexer submodule
    output_multiplexer #(
        .WIDTH(WIDTH)
    ) u_output_multiplexer (
        .data_a(A),
        .data_b(two_complement_A_int),
        .select(control),
        .data_out(Y)
    );

endmodule

// Submodule to calculate the two's complement of an input
module two_complement_calculator #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] inverted_data_in;
    wire [WIDTH-1:0] add_one_result;

    // Invert the input data
    assign inverted_data_in = ~data_in;

    // Add 1 to the inverted data
    assign add_one_result = inverted_data_in + 1;

    // Output the two's complement result
    assign data_out = add_one_result;

endmodule

// Submodule to multiplex between two data inputs based on a select signal
module output_multiplexer #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_a,
    input wire [WIDTH-1:0] data_b,
    input wire select,
    output wire [WIDTH-1:0] data_out
);

    // Select between data_b and data_a based on the select signal
    assign data_out = select ? data_b : data_a;

endmodule