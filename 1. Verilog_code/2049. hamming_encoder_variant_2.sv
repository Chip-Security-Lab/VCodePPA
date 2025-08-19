//SystemVerilog
// Top-Level Hamming (7,4) Encoder Module with Hierarchical Structure

module hamming_encoder (
    input  wire [3:0] data_in,         // 4-bit input data
    output wire [6:0] hamming_out      // 7-bit Hamming encoded output
);

    // Internal wires for connecting submodules
    wire [2:0] parity_bits_internal;
    wire [3:0] data_bits_internal;

    // ------------------------------------------------------------
    // Parity Generation Submodule Instance
    // ------------------------------------------------------------
    hamming_parity_generator u_parity_generator (
        .data_in      (data_in),
        .parity_bits  (parity_bits_internal)
    );

    // ------------------------------------------------------------
    // Data Mapping Submodule Instance
    // ------------------------------------------------------------
    hamming_data_mapper u_data_mapper (
        .data_in   (data_in),
        .data_out  (data_bits_internal)
    );

    // ------------------------------------------------------------
    // Output Packing Submodule Instance
    // ------------------------------------------------------------
    hamming_output_packer u_output_packer (
        .parity_bits (parity_bits_internal),
        .data_bits   (data_bits_internal),
        .hamming_out (hamming_out)
    );

endmodule

// ------------------------------------------------------------
// Parity Generator Submodule
// Purpose: Computes 3 parity bits for Hamming (7,4) encoding from 4 data bits
// parity_bits[0]: Overall parity for positions 1,3,5,7
// parity_bits[1]: Overall parity for positions 2,3,6,7
// parity_bits[2]: Overall parity for positions 4,5,6,7
// ------------------------------------------------------------
module hamming_parity_generator (
    input  wire [3:0] data_in,
    output wire [2:0] parity_bits
);

    assign parity_bits[0] = data_in[0] ^ data_in[1] ^ data_in[3];
    assign parity_bits[1] = data_in[0] ^ data_in[2] ^ data_in[3];
    assign parity_bits[2] = data_in[1] ^ data_in[2] ^ data_in[3];

endmodule

// ------------------------------------------------------------
// Data Mapper Submodule
// Purpose: Maps 4 input data bits to their respective Hamming codeword positions
// data_out[0]: To position 3 (hamming_out[2])
// data_out[1]: To position 5 (hamming_out[4])
// data_out[2]: To position 6 (hamming_out[5])
// data_out[3]: To position 7 (hamming_out[6])
// ------------------------------------------------------------
module hamming_data_mapper (
    input  wire [3:0] data_in,
    output wire [3:0] data_out
);

    assign data_out[0] = data_in[0];
    assign data_out[1] = data_in[1];
    assign data_out[2] = data_in[2];
    assign data_out[3] = data_in[3];

endmodule

// ------------------------------------------------------------
// Output Packer Submodule
// Purpose: Combines parity bits and data bits into the final 7-bit Hamming output codeword
// hamming_out[0]: Parity bit 1
// hamming_out[1]: Parity bit 2
// hamming_out[2]: Data bit 1
// hamming_out[3]: Parity bit 3
// hamming_out[4]: Data bit 2
// hamming_out[5]: Data bit 3
// hamming_out[6]: Data bit 4
// ------------------------------------------------------------
module hamming_output_packer (
    input  wire [2:0] parity_bits,
    input  wire [3:0] data_bits,
    output wire [6:0] hamming_out
);

    assign hamming_out[0] = parity_bits[0];
    assign hamming_out[1] = parity_bits[1];
    assign hamming_out[2] = data_bits[0];
    assign hamming_out[3] = parity_bits[2];
    assign hamming_out[4] = data_bits[1];
    assign hamming_out[5] = data_bits[2];
    assign hamming_out[6] = data_bits[3];

endmodule