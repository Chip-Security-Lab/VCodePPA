//SystemVerilog
// Top-level module: parameterized multiplexer with subtraction demonstration
module param_mux #(
    parameter DATA_WIDTH = 8,
    parameter MUX_DEPTH = 4
) (
    input  wire [DATA_WIDTH-1:0] data_in [MUX_DEPTH-1:0],
    input  wire [$clog2(MUX_DEPTH)-1:0] select,
    output wire [DATA_WIDTH-1:0] data_out
);
    // Internal wires for submodule connections
    wire [DATA_WIDTH-1:0] mux_selected_data;
    wire [DATA_WIDTH-1:0] subtraction_result;

    // Multiplexer submodule: selects one of the data inputs
    mux_onehot #(
        .DATA_WIDTH(DATA_WIDTH),
        .MUX_DEPTH(MUX_DEPTH)
    ) u_mux_onehot (
        .data_in(data_in),
        .select(select),
        .data_out(mux_selected_data)
    );

    // Subtraction demonstration: subtract data_in[1] from data_in[0]
    subtractor_unit #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_subtractor_unit (
        .minuend(data_in[0]),
        .subtrahend(data_in[1]),
        .difference(subtraction_result)
    );

    // Output assignment (as in original: only mux result is output)
    assign data_out = mux_selected_data;

endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_onehot
// Parameterized multiplexer, selects data input based on select signal
// -----------------------------------------------------------------------------
module mux_onehot #(
    parameter DATA_WIDTH = 8,
    parameter MUX_DEPTH = 4
) (
    input  wire [DATA_WIDTH-1:0] data_in [MUX_DEPTH-1:0],
    input  wire [$clog2(MUX_DEPTH)-1:0] select,
    output wire [DATA_WIDTH-1:0] data_out
);
    assign data_out = data_in[select];
endmodule

// -----------------------------------------------------------------------------
// Submodule: subtractor_unit
// Parameterized 8-bit subtraction using conditional sum subtraction
// -----------------------------------------------------------------------------
module subtractor_unit #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] minuend,
    input  wire [DATA_WIDTH-1:0] subtrahend,
    output wire [DATA_WIDTH-1:0] difference
);
    wire [DATA_WIDTH-1:0] subtrahend_complement;

    // Bitwise inversion for two's complement
    assign subtrahend_complement = ~subtrahend;

    // Conditional sum subtraction (for 8 bits, using two 4-bit groups)
    wire [3:0] sum_lower_0, sum_lower_1, sum_upper_0, sum_upper_1;
    wire       carry_lower, carry_upper;

    // Lower 4 bits group
    conditional_sum_adder_4bit u_csa_lower (
        .a(minuend[3:0]),
        .b(subtrahend_complement[3:0]),
        .carry_in(1'b1),
        .sum0(sum_lower_0),
        .sum1(sum_lower_1),
        .carry_out(carry_lower)
    );

    // Upper 4 bits group
    conditional_sum_adder_4bit u_csa_upper (
        .a(minuend[7:4]),
        .b(subtrahend_complement[7:4]),
        .carry_in(carry_lower),
        .sum0(sum_upper_0),
        .sum1(sum_upper_1),
        .carry_out(carry_upper)
    );

    // Combine both groups to form the result
    assign difference = {sum_upper_0, sum_lower_0};

endmodule

// -----------------------------------------------------------------------------
// Submodule: conditional_sum_adder_4bit
// 4-bit conditional sum adder for fast addition with selectable carry-in
// -----------------------------------------------------------------------------
module conditional_sum_adder_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       carry_in,
    output wire [3:0] sum0,
    output wire [3:0] sum1,
    output wire       carry_out
);
    // Precompute sums and carries for carry_in = 0
    wire [3:0] sum_c0;
    wire       carry_c0;
    assign {carry_c0, sum_c0} = a + b + 4'b0000;

    // Precompute sums and carries for carry_in = 1
    wire [3:0] sum_c1;
    wire       carry_c1;
    assign {carry_c1, sum_c1} = a + b + 4'b0001;

    // Select based on carry_in
    assign sum0 = (carry_in == 1'b0) ? sum_c0 : sum_c1;
    assign sum1 = (carry_in == 1'b1) ? sum_c1 : sum_c0;
    assign carry_out = (carry_in == 1'b0) ? carry_c0 : carry_c1;
endmodule