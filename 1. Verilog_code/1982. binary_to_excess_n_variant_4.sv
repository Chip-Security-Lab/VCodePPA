//SystemVerilog
// Top-level module: Hierarchical binary to excess-N code converter
module binary_to_excess_n #(
    parameter WIDTH = 8,
    parameter N = 127
)(
    input  wire [WIDTH-1:0] binary_in,
    output wire [WIDTH-1:0] excess_n_out
);

    // Internal signal for adder result
    wire [WIDTH-1:0] adder_sum;

    // Instantiate adder submodule
    binary_to_excess_n_adder #(
        .WIDTH(WIDTH),
        .N(N)
    ) u_adder (
        .data_in(binary_in),
        .sum_out(adder_sum)
    );

    // Instantiate output register submodule
    binary_to_excess_n_reg #(
        .WIDTH(WIDTH)
    ) u_reg (
        .data_in(adder_sum),
        .data_out(excess_n_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: binary_to_excess_n_adder
// Function: Adds constant N to binary input
// -----------------------------------------------------------------------------
module binary_to_excess_n_adder #(
    parameter WIDTH = 8,
    parameter N = 127
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] sum_out
);
    assign sum_out = data_in + N;
endmodule

// -----------------------------------------------------------------------------
// Submodule: binary_to_excess_n_reg
// Function: Output register for improved timing and PPA
// -----------------------------------------------------------------------------
module binary_to_excess_n_reg #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // Pass-through combinational logic (can be replaced with sequential logic for timing)
    assign data_out = data_in;
endmodule