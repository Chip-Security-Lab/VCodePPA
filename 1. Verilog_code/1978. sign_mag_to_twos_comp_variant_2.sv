//SystemVerilog
// Top-level module: sign_mag_to_twos_comp
// Converts sign-magnitude representation to two's complement.
// Hierarchically organized for clarity and reuse.

module sign_mag_to_twos_comp #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] sign_mag_in,
    output wire [WIDTH-1:0] twos_comp_out
);

    wire sign_flag;
    wire [WIDTH-2:0] magnitude_bits;
    wire [WIDTH-2:0] magnitude_cond_inv;
    wire [WIDTH-1:0] negative_twos_comp;
    wire [WIDTH-1:0] twos_comp_final;

    // Extract sign and magnitude
    sign_mag_extract #(
        .WIDTH(WIDTH)
    ) u_sign_mag_extract (
        .sign_mag_in(sign_mag_in),
        .sign_flag(sign_flag),
        .magnitude_bits(magnitude_bits)
    );

    // Negate magnitude (two's complement) via conditional inversion adder
    magnitude_conditional_invert #(
        .WIDTH(WIDTH-1)
    ) u_magnitude_conditional_invert (
        .magnitude_in(magnitude_bits),
        .invert_enable(sign_flag),
        .result_out(magnitude_cond_inv)
    );

    // Combine sign and processed magnitude to form negative two's complement
    assign negative_twos_comp = {1'b1, magnitude_cond_inv};

    // Select output based on sign
    twos_comp_mux #(
        .WIDTH(WIDTH)
    ) u_twos_comp_mux (
        .sign_flag(sign_flag),
        .sign_mag_in(sign_mag_in),
        .negative_twos_comp(negative_twos_comp),
        .twos_comp_out(twos_comp_final)
    );

    assign twos_comp_out = twos_comp_final;

endmodule

// -----------------------------------------------------------------------------
// Submodule: sign_mag_extract
// Extracts the sign bit and magnitude from sign-magnitude input.
// -----------------------------------------------------------------------------
module sign_mag_extract #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] sign_mag_in,
    output wire             sign_flag,
    output wire [WIDTH-2:0] magnitude_bits
);
    assign sign_flag = sign_mag_in[WIDTH-1];
    assign magnitude_bits = sign_mag_in[WIDTH-2:0];
endmodule

// -----------------------------------------------------------------------------
// Submodule: magnitude_conditional_invert
// Conditional inversion adder for two's complement negation.
// -----------------------------------------------------------------------------
module magnitude_conditional_invert #(
    parameter WIDTH = 7
)(
    input  wire [WIDTH-1:0] magnitude_in,
    input  wire             invert_enable,
    output wire [WIDTH-1:0] result_out
);
    wire [WIDTH-1:0] inverted_magnitude;
    wire [WIDTH-1:0] sum_result;
    wire             carry_in;
    integer i;

    assign inverted_magnitude = invert_enable ? ~magnitude_in : magnitude_in;
    assign carry_in = invert_enable ? 1'b1 : 1'b0;

    // Ripple-carry adder for conditional inversion (+1 if invert_enable)
    reg [WIDTH-1:0] sum_reg;
    reg             carry;
    always @* begin
        carry = carry_in;
        for (i = 0; i < WIDTH; i = i + 1) begin
            sum_reg[i] = inverted_magnitude[i] ^ carry;
            carry = (inverted_magnitude[i] & carry) | (magnitude_in[i] & ~invert_enable & carry);
        end
    end
    assign result_out = sum_reg;
endmodule

// -----------------------------------------------------------------------------
// Submodule: twos_comp_mux
// Selects the correct output based on the sign bit.
// -----------------------------------------------------------------------------
module twos_comp_mux #(
    parameter WIDTH = 8
)(
    input  wire             sign_flag,
    input  wire [WIDTH-1:0] sign_mag_in,
    input  wire [WIDTH-1:0] negative_twos_comp,
    output wire [WIDTH-1:0] twos_comp_out
);
    assign twos_comp_out = sign_flag ? negative_twos_comp : sign_mag_in;
endmodule