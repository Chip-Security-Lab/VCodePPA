//SystemVerilog
// Top-level Module: Hierarchical gray_to_bin Converter

module gray_to_bin #(
    parameter DATA_W = 8
)(
    input  wire [DATA_W-1:0] gray_code,
    output wire [DATA_W-1:0] binary
);

    // Internal signal for binary conversion
    wire [DATA_W-1:0] binary_internal;

    // MSB Assignment Submodule
    gray_to_bin_msb #(
        .DATA_W(DATA_W)
    ) u_msb_assign (
        .gray_code(gray_code),
        .binary_msb(binary_internal[DATA_W-1])
    );

    // Recursive Subtractor Chain Submodule
    gray_to_bin_subtractor_chain #(
        .DATA_W(DATA_W)
    ) u_subtractor_chain (
        .gray_code(gray_code),
        .binary_in_msb(binary_internal[DATA_W-1]),
        .binary_rest(binary_internal[DATA_W-2:0])
    );

    // Output assignment
    assign binary = binary_internal;

endmodule

// -----------------------------------------------------------------------------
// Submodule: gray_to_bin_msb
// Function: Assigns the MSB of the binary output directly from the Gray code MSB
// -----------------------------------------------------------------------------
module gray_to_bin_msb #(
    parameter DATA_W = 8
)(
    input  wire [DATA_W-1:0] gray_code,
    output wire               binary_msb
);
    assign binary_msb = gray_code[DATA_W-1];
endmodule

// -----------------------------------------------------------------------------
// Submodule: gray_to_bin_subtractor_chain
// Function: Computes the remaining binary bits using two's complement subtraction
//           in a recursive subtractor chain
// -----------------------------------------------------------------------------
module gray_to_bin_subtractor_chain #(
    parameter DATA_W = 8
)(
    input  wire [DATA_W-1:0] gray_code,
    input  wire               binary_in_msb,
    output wire [DATA_W-2:0] binary_rest
);

    // Internal wires for the subtractor chain
    wire [DATA_W-1:0] binary_chain;

    assign binary_chain[DATA_W-1] = binary_in_msb;

    genvar idx;
    generate
        for (idx = DATA_W-2; idx >= 0; idx = idx - 1) begin : gen_subtractor
            // Each stage computes: binary_chain[idx] = binary_chain[idx+1] + (~gray_code[idx] + 1'b1)
            gray_to_bin_subtractor_stage u_stage (
                .prev_binary (binary_chain[idx+1]),
                .gray_bit    (gray_code[idx]),
                .binary_bit  (binary_chain[idx])
            );
        end
    endgenerate

    assign binary_rest = binary_chain[DATA_W-2:0];

endmodule

// -----------------------------------------------------------------------------
// Submodule: gray_to_bin_subtractor_stage
// Function: Performs two's complement subtraction for a single bit stage
//           binary_bit = prev_binary + (~gray_bit + 1)
// -----------------------------------------------------------------------------
module gray_to_bin_subtractor_stage(
    input  wire prev_binary,
    input  wire gray_bit,
    output wire binary_bit
);
    assign binary_bit = prev_binary + (~gray_bit + 1'b1);
endmodule