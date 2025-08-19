//SystemVerilog
// Parity calculation submodule
module parity_calc(
    input [7:0] data_in,
    output [3:0] parity_bits
);
    // Calculate individual parity bits
    assign parity_bits[0] = data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[6];
    assign parity_bits[1] = data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6];
    assign parity_bits[2] = data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[7];
    assign parity_bits[3] = ^data_in; // Overall parity
endmodule

// Data path submodule
module data_path(
    input [7:0] data_in,
    output [7:0] data_out
);
    // Direct data path
    assign data_out = data_in;
endmodule

// Top-level Hamming encoder module
module async_hamming_enc_8bit(
    input [7:0] din,
    output [11:0] enc_out
);
    wire [3:0] parity_bits;
    wire [7:0] data_path_out;
    
    // Instantiate submodules
    parity_calc parity_unit(
        .data_in(din),
        .parity_bits(parity_bits)
    );
    
    data_path data_unit(
        .data_in(din),
        .data_out(data_path_out)
    );
    
    // Combine outputs
    assign enc_out[0] = parity_bits[0];
    assign enc_out[1] = parity_bits[1];
    assign enc_out[2] = data_path_out[0];
    assign enc_out[3] = parity_bits[2];
    assign enc_out[4] = data_path_out[1];
    assign enc_out[5] = data_path_out[2];
    assign enc_out[6] = data_path_out[3];
    assign enc_out[7] = data_path_out[4];
    assign enc_out[8] = data_path_out[5];
    assign enc_out[9] = data_path_out[6];
    assign enc_out[10] = data_path_out[7];
    assign enc_out[11] = parity_bits[3];
endmodule