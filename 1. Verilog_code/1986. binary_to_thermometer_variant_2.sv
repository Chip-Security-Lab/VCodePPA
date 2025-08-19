//SystemVerilog
// Top-level module: Hierarchical binary to thermometer encoder
module binary_to_thermometer #(
    parameter BINARY_WIDTH = 3
)(
    input  wire [BINARY_WIDTH-1:0] binary_in,
    output wire [2**BINARY_WIDTH-2:0] thermo_out
);

    // Internal signal for expanded thermometer output
    wire [2**BINARY_WIDTH-2:0] thermometer_bits;

    // Instantiate the thermometer encoder core
    thermometer_encoder_core #(
        .BINARY_WIDTH(BINARY_WIDTH)
    ) u_thermometer_encoder_core (
        .binary_value(binary_in),
        .thermo_code(thermometer_bits)
    );

    // Output assignment
    assign thermo_out = thermometer_bits;

endmodule

// --------------------------------------------------------------------------
// Submodule: thermometer_encoder_core
// Function: Converts binary input to thermometer code
// Inputs:
//   - binary_value: Binary encoded value
// Outputs:
//   - thermo_code: One-hot thermometer code output
// --------------------------------------------------------------------------
module thermometer_encoder_core #(
    parameter BINARY_WIDTH = 3
)(
    input  wire [BINARY_WIDTH-1:0] binary_value,
    output reg  [2**BINARY_WIDTH-2:0] thermo_code
);
    integer idx;
    wire [BINARY_WIDTH-1:0] idx_bin [0:2**BINARY_WIDTH-2];
    wire [BINARY_WIDTH-1:0] sub_result [0:2**BINARY_WIDTH-2];
    wire borrow_out [0:2**BINARY_WIDTH-2];
    genvar i;

    // Generate binary representations of idx
    generate
        for (i = 0; i < 2**BINARY_WIDTH-1; i = i + 1) begin : IDX_BIN_GEN
            assign idx_bin[i] = i[BINARY_WIDTH-1:0];
        end
    endgenerate

    // Instantiate 3-bit borrow subtractors
    generate
        for (i = 0; i < 2**BINARY_WIDTH-1; i = i + 1) begin : BORROW_SUB_GEN
            borrow_subtractor_3bit u_borrow_subtractor_3bit (
                .minuend(binary_value),
                .subtrahend(idx_bin[i]),
                .difference(sub_result[i]),
                .borrow_out(borrow_out[i])
            );
        end
    endgenerate

    always @* begin
        for (idx = 0; idx < 2**BINARY_WIDTH-1; idx = idx + 1) begin
            // If no borrow, binary_value >= idx, so set thermometer bit
            thermo_code[idx] = ~borrow_out[idx];
        end
    end

endmodule

// --------------------------------------------------------------------------
// Submodule: 3-bit Borrow Subtractor
// Function: Performs 3-bit subtraction using borrow logic
// Inputs:
//   - minuend:     3-bit input to subtract from
//   - subtrahend:  3-bit input to subtract
// Outputs:
//   - difference:  3-bit difference
//   - borrow_out:  Final borrow out (1 if minuend < subtrahend)
// --------------------------------------------------------------------------
module borrow_subtractor_3bit (
    input  wire [2:0] minuend,
    input  wire [2:0] subtrahend,
    output wire [2:0] difference,
    output wire       borrow_out
);
    wire borrow0, borrow1, borrow2;

    // Bit 0
    assign difference[0] = minuend[0] ^ subtrahend[0];
    assign borrow0 = (~minuend[0]) & subtrahend[0];

    // Bit 1
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow0;
    assign borrow1 = ((~minuend[1]) & subtrahend[1]) | (((~minuend[1]) | subtrahend[1]) & borrow0);

    // Bit 2
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow1;
    assign borrow2 = ((~minuend[2]) & subtrahend[2]) | (((~minuend[2]) | subtrahend[2]) & borrow1);

    assign borrow_out = borrow2;

endmodule