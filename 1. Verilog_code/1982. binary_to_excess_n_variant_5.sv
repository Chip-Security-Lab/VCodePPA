//SystemVerilog
// Top-level module: Hierarchical binary to excess-N code converter
module binary_to_excess_n #(
    parameter WIDTH = 8,
    parameter N = 127
)(
    input  wire [WIDTH-1:0] binary_in,
    output wire [WIDTH-1:0] excess_n_out
);

    wire [WIDTH-1:0] excess_sum;

    // Submodule: Excess-N Adder
    excess_n_adder #(
        .WIDTH(WIDTH),
        .N(N)
    ) u_excess_n_adder (
        .data_in(binary_in),
        .excess_sum(excess_sum)
    );

    // Submodule: Output Register (combinational assignment for reg compatibility)
    excess_n_output_reg #(
        .WIDTH(WIDTH)
    ) u_excess_n_output_reg (
        .sum_in(excess_sum),
        .excess_n_out(excess_n_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: Excess-N Adder
// Adds the constant N to the input binary value
// -----------------------------------------------------------------------------
module excess_n_adder #(
    parameter WIDTH = 8,
    parameter N = 127
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] excess_sum
);
    assign excess_sum = data_in + N;
endmodule

// -----------------------------------------------------------------------------
// Submodule: Output Register (combinational assignment for reg compatibility)
// Passes the adder output to the module output
// -----------------------------------------------------------------------------
module excess_n_output_reg #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] sum_in,
    output wire [WIDTH-1:0] excess_n_out
);
    assign excess_n_out = sum_in;
endmodule