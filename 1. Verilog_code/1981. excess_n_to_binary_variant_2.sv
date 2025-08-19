//SystemVerilog
// Top-level module: Hierarchically converts Excess-N code to binary using structured submodules
module excess_n_to_binary_top #(parameter WIDTH = 8, N = 127) (
    input  wire [WIDTH-1:0] excess_n_in,
    output wire [WIDTH-1:0] binary_out
);

    // Internal signal for the subtraction result
    wire [WIDTH-1:0] subtract_result;

    // Instantiate the subtraction logic submodule
    excess_n_subtractor_unit #(
        .WIDTH(WIDTH),
        .N(N)
    ) u_subtractor (
        .in_excess_n(excess_n_in),
        .out_binary(subtract_result)
    );

    // Instantiate the output register submodule
    excess_n_output_register #(
        .WIDTH(WIDTH)
    ) u_output_register (
        .in_data(subtract_result),
        .out_data(binary_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: excess_n_subtractor_unit
// Function: Performs Excess-N to binary conversion by subtracting N from input
// -----------------------------------------------------------------------------
module excess_n_subtractor_unit #(parameter WIDTH = 8, N = 127) (
    input  wire [WIDTH-1:0] in_excess_n,
    output wire [WIDTH-1:0] out_binary
);
    assign out_binary = in_excess_n - N;
endmodule

// -----------------------------------------------------------------------------
// Submodule: excess_n_output_register
// Function: Passes input to output (combinational). Replace with clocked reg for pipelining.
// -----------------------------------------------------------------------------
module excess_n_output_register #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);
    assign out_data = in_data;
endmodule