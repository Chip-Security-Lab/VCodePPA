//SystemVerilog
// Top-level module: Two's Complement to Sign-Magnitude Converter (Hierarchical, 8 bits)
module twos_comp_to_sign_mag #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] twos_comp_in,
    output wire [WIDTH-1:0] sign_mag_out
);

    // Signal declarations for inter-module connections
    wire sign_bit;
    wire [WIDTH-2:0] magnitude_bits;
    wire [WIDTH-2:0] magnitude_out;

    // Extractor submodule: Extracts sign and magnitude from two's complement input
    twos_comp_extractor #(
        .WIDTH(WIDTH)
    ) u_extractor (
        .twos_comp_in   (twos_comp_in),
        .sign_bit       (sign_bit),
        .magnitude_bits (magnitude_bits)
    );

    // Magnitude Converter submodule: Converts two's complement magnitude to sign-magnitude
    twos_comp_magnitude_converter #(
        .WIDTH(WIDTH)
    ) u_magnitude_converter (
        .sign_bit       (sign_bit),
        .magnitude_in   (magnitude_bits),
        .magnitude_out  (magnitude_out)
    );

    // Output Assembler: Combines sign and magnitude into final output
    assign sign_mag_out = {sign_bit, magnitude_out};

endmodule

// -----------------------------------------------------------------------------
// Submodule: Two's Complement Extractor
// Function: Extracts sign bit and magnitude bits from the two's complement input
// -----------------------------------------------------------------------------
module twos_comp_extractor #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] twos_comp_in,
    output wire             sign_bit,
    output wire [WIDTH-2:0] magnitude_bits
);
    assign sign_bit       = twos_comp_in[WIDTH-1];
    assign magnitude_bits = twos_comp_in[WIDTH-2:0];
endmodule

// -----------------------------------------------------------------------------
// Submodule: Magnitude Converter with Conditional Sum Subtraction
// Function: Converts two's complement magnitude to sign-magnitude based on sign
//           Uses conditional sum algorithm for subtraction (two's complement negation)
// -----------------------------------------------------------------------------
module twos_comp_magnitude_converter #(
    parameter WIDTH = 8
)(
    input  wire             sign_bit,
    input  wire [WIDTH-2:0] magnitude_in,
    output wire [WIDTH-2:0] magnitude_out
);

    wire [WIDTH-2:0] inverted_magnitude;
    wire [WIDTH-2:0] sum_result;
    wire             carry_0, carry_1;
    wire [WIDTH-2:0] sum_0, sum_1;

    assign inverted_magnitude = ~magnitude_in;

    // Conditional sum adder for (inverted_magnitude + 1)
    // Stage 0: Precompute sum and carry for carry-in = 0 and carry-in = 1
    assign sum_0[0] = inverted_magnitude[0] ^ 1'b0;
    assign carry_0  = inverted_magnitude[0] & 1'b0;
    assign sum_1[0] = inverted_magnitude[0] ^ 1'b1;
    assign carry_1  = inverted_magnitude[0] & 1'b1;

    genvar i;
    generate
        for (i = 1; i < WIDTH-1; i = i + 1) begin : gen_conditional_sum
            assign sum_0[i] = inverted_magnitude[i] ^ carry_0;
            assign sum_1[i] = inverted_magnitude[i] ^ carry_1;
        end
    endgenerate

    // Select sum based on carry propagation
    wire [WIDTH-2:0] conditional_sum;
    assign conditional_sum = (sign_bit) ? sum_1 : magnitude_in;

    // Output assignment
    assign magnitude_out = (sign_bit) ? conditional_sum : magnitude_in;

endmodule