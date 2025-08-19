//SystemVerilog
// Top-level module: Integer to Fraction Converter (Hierarchical Version)
module integer_to_fraction #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] int_in,
    input  wire [INT_WIDTH-1:0] denominator,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_out
);

    // Internal signal for shifted integer
    wire [INT_WIDTH+FRAC_WIDTH-1:0] shifted_int;
    // Internal signal for normalized denominator
    wire [INT_WIDTH+FRAC_WIDTH-1:0] norm_denominator;
    // Internal signal for division result
    wire [INT_WIDTH+FRAC_WIDTH-1:0] division_result;

    // Integer Left Shifter: Aligns integer input with fractional width
    int_left_shifter #(
        .INT_WIDTH(INT_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) u_int_left_shifter (
        .int_in(int_in),
        .shifted_int(shifted_int)
    );

    // Denominator Normalizer: Zero-extends denominator to match numerator width
    denominator_normalizer #(
        .INT_WIDTH(INT_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) u_denominator_normalizer (
        .denominator_in(denominator),
        .denominator_out(norm_denominator)
    );

    // Fractional Divider: Performs division to obtain fractional output
    fractional_divider #(
        .WIDTH(INT_WIDTH+FRAC_WIDTH)
    ) u_fractional_divider (
        .numerator(shifted_int),
        .denominator(norm_denominator),
        .result(division_result)
    );

    // Output assignment
    assign frac_out = division_result;

endmodule

// -----------------------------------------------------------------------------
// Integer Left Shifter
// Shifts the integer input by FRAC_WIDTH bits to the left
// -----------------------------------------------------------------------------
module int_left_shifter #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] int_in,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] shifted_int
);
    assign shifted_int = {int_in, {FRAC_WIDTH{1'b0}}};
endmodule

// -----------------------------------------------------------------------------
// Denominator Normalizer
// Zero-extends the denominator to match the required width for division
// -----------------------------------------------------------------------------
module denominator_normalizer #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] denominator_in,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] denominator_out
);
    assign denominator_out = {{FRAC_WIDTH{1'b0}}, denominator_in};
endmodule

// -----------------------------------------------------------------------------
// Fractional Divider
// Divides numerator by denominator to produce a fixed-point result
// -----------------------------------------------------------------------------
module fractional_divider #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] numerator,
    input  wire [WIDTH-1:0] denominator,
    output wire [WIDTH-1:0] result
);
    assign result = denominator != 0 ? numerator / denominator : {WIDTH{1'b0}};
endmodule