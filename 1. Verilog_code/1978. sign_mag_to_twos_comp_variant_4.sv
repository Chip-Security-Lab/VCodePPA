//SystemVerilog
// Top-level module: sign_mag_to_twos_comp
// Hierarchically converts sign-magnitude to two's complement representation
module sign_mag_to_twos_comp #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] sign_mag_in,
    output wire [WIDTH-1:0] twos_comp_out
);

    wire sign_bit;
    wire [WIDTH-2:0] magnitude;
    wire [WIDTH-2:0] magnitude_twos;
    wire [WIDTH-1:0] negative_result;
    wire [WIDTH-1:0] positive_result;

    // Extract sign and magnitude
    sign_mag_extract #(
        .WIDTH(WIDTH)
    ) u_sign_mag_extract (
        .sign_mag_in(sign_mag_in),
        .sign_bit(sign_bit),
        .magnitude(magnitude)
    );

    // Convert magnitude to two's complement (negate magnitude)
    magnitude_negate #(
        .WIDTH(WIDTH-1)
    ) u_magnitude_negate (
        .magnitude_in(magnitude),
        .negated_out(magnitude_twos)
    );

    // Combine sign with magnitude conversion
    assign negative_result = {1'b1, magnitude_twos};
    assign positive_result = sign_mag_in;

    // Multiplexer to select output based on sign
    sign_mux #(
        .WIDTH(WIDTH)
    ) u_sign_mux (
        .sign_bit(sign_bit),
        .negative_in(negative_result),
        .positive_in(positive_result),
        .out(twos_comp_out)
    );

endmodule

// ---------------------------------------------------------------------------
// Submodule: sign_mag_extract
// Extracts the sign bit and magnitude from the sign-magnitude input
module sign_mag_extract #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] sign_mag_in,
    output wire             sign_bit,
    output wire [WIDTH-2:0] magnitude
);
    assign sign_bit = sign_mag_in[WIDTH-1];
    assign magnitude = sign_mag_in[WIDTH-2:0];
endmodule

// ---------------------------------------------------------------------------
// Submodule: magnitude_negate
// Computes the two's complement (negation) of the input magnitude
module magnitude_negate #(
    parameter WIDTH = 15
)(
    input  wire [WIDTH-1:0] magnitude_in,
    output wire [WIDTH-1:0] negated_out
);
    assign negated_out = ~magnitude_in + {{(WIDTH-1){1'b0}}, 1'b1};
endmodule

// ---------------------------------------------------------------------------
// Submodule: sign_mux
// Selects between positive and negative results based on sign bit
module sign_mux #(
    parameter WIDTH = 16
)(
    input  wire             sign_bit,
    input  wire [WIDTH-1:0] negative_in,
    input  wire [WIDTH-1:0] positive_in,
    output wire [WIDTH-1:0] out
);
    reg [WIDTH-1:0] mux_out;
    always @(*) begin
        if (sign_bit) begin
            mux_out = negative_in;
        end else begin
            mux_out = positive_in;
        end
    end
    assign out = mux_out;
endmodule