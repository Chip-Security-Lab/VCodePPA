//SystemVerilog
// Top-level module: Hierarchically structured binary-to-thermometer code converter
module binary_to_thermometer #(
    parameter BINARY_WIDTH = 3
)(
    input  wire [BINARY_WIDTH-1:0] binary_in,
    output wire [2**BINARY_WIDTH-2:0] thermo_out
);

    // Internal signals for each thermometer bit
    wire [2**BINARY_WIDTH-2:0] thermometer_bits;

    genvar idx;
    generate
        for (idx = 0; idx < 2**BINARY_WIDTH-1; idx = idx + 1) begin: gen_thermo_bit
            // Instantiate the single bit thermometer encoder for each output bit
            thermo_bit_encoder_prefix_subtractor #(
                .BIT_INDEX(idx),
                .BINARY_WIDTH(BINARY_WIDTH)
            ) u_thermo_bit_encoder (
                .binary_in(binary_in),
                .thermo_bit(thermometer_bits[idx])
            );
        end
    endgenerate

    // Assign the output
    assign thermo_out = thermometer_bits;

endmodule

// -------------------------------------------------------------------------
// Submodule: Parallel Prefix Subtractor (3-bit) Based Thermo Bit Encoder
// Description: Encodes a single thermometer output bit based on the binary input.
//              Outputs 1 if BIT_INDEX < binary_in, else 0.
//              Uses a parallel prefix subtractor for comparison.
// -------------------------------------------------------------------------
module thermo_bit_encoder_prefix_subtractor #(
    parameter BIT_INDEX = 0,
    parameter BINARY_WIDTH = 3
)(
    input  wire [BINARY_WIDTH-1:0] binary_in,
    output wire thermo_bit
);

    // Parallel Prefix Subtractor for 3-bit: Computes (binary_in - BIT_INDEX)
    wire [BINARY_WIDTH-1:0] a;
    wire [BINARY_WIDTH-1:0] b;
    wire [BINARY_WIDTH-1:0] b_inverted;
    wire [BINARY_WIDTH:0]   carry;
    wire [BINARY_WIDTH-1:0] difference;

    assign a = binary_in;
    assign b = BIT_INDEX[BINARY_WIDTH-1:0];

    assign b_inverted = ~b;
    assign carry[0] = 1'b1;

    // Stage 0: Propagate and Generate signals
    wire [BINARY_WIDTH-1:0] p;
    wire [BINARY_WIDTH-1:0] g;

    assign p = a ^ b_inverted;        // Propagate
    assign g = a & b_inverted;        // Generate

    // Parallel prefix carry computation (Kogge-Stone for 3 bits)
    // Level 1
    wire [BINARY_WIDTH-1:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];

    // Level 2
    wire [BINARY_WIDTH-1:0] g2;
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);

    // Compute carries
    assign carry[1] = g2[0] | (p[0] & carry[0]);
    assign carry[2] = g2[1] | (p[1] & carry[1]);
    assign carry[3] = g2[2] | (p[2] & carry[2]);

    // Compute difference
    assign difference[0] = p[0] ^ carry[0];
    assign difference[1] = p[1] ^ carry[1];
    assign difference[2] = p[2] ^ carry[2];

    // Detect if binary_in > BIT_INDEX (i.e., if MSB carry out is 0, a > b)
    // For 3-bit, a < b if carry[3] == 0
    // a > b if carry[3] == 1
    // a == b if difference == 0

    // For thermometer encoding, output 1 if BIT_INDEX < binary_in
    assign thermo_bit = carry[3];

endmodule