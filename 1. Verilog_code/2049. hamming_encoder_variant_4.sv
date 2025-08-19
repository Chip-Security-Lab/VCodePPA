//SystemVerilog
// Top-level Hamming Encoder module
module hamming_encoder (
    input wire [3:0] data_in,
    output wire [6:0] hamming_out
);

    wire [3:0] extracted_data;
    wire [3:0] generated_parity;

    // Data Extraction Submodule
    data_extractor u_data_extractor (
        .data_in     (data_in),
        .d           (extracted_data)
    );

    // Parity Calculation Submodule
    parity_generator u_parity_generator (
        .d           (extracted_data),
        .parity      (generated_parity)
    );

    // Output Mapping Submodule
    output_mapper u_output_mapper (
        .d           (extracted_data),
        .parity      (generated_parity),
        .hamming_out (hamming_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Submodule: Data Extractor
//-----------------------------------------------------------------------------
module data_extractor (
    input  wire [3:0] data_in,
    output wire [3:0] d
);
    assign d = data_in;
endmodule

//-----------------------------------------------------------------------------
// Submodule: Parity Generator (with simplified Boolean expressions)
//-----------------------------------------------------------------------------
module parity_generator (
    input  wire [3:0] d,
    output wire [3:0] parity
);
    // Simplified Boolean expressions using minimal XOR logic:
    // parity[0] = d[0] ^ d[1] ^ d[3]
    // parity[1] = d[0] ^ d[2] ^ d[3]
    // parity[2] = d[1] ^ d[2] ^ d[3]
    // parity[3] = 1'b0 (unused)

    assign parity[0] = d[0] ^ d[1] ^ d[3];
    assign parity[1] = d[0] ^ d[2] ^ d[3];
    assign parity[2] = d[1] ^ d[2] ^ d[3];
    assign parity[3] = 1'b0;
endmodule

//-----------------------------------------------------------------------------
// Submodule: Output Mapper
//-----------------------------------------------------------------------------
module output_mapper (
    input  wire [3:0] d,
    input  wire [3:0] parity,
    output wire [6:0] hamming_out
);
    assign hamming_out[0] = parity[0];
    assign hamming_out[1] = parity[1];
    assign hamming_out[2] = d[0];
    assign hamming_out[3] = parity[2];
    assign hamming_out[4] = d[1];
    assign hamming_out[5] = d[2];
    assign hamming_out[6] = d[3];
endmodule