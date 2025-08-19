//SystemVerilog
module hamming_encoder (
    input  [3:0] data_in,
    output [6:0] encoded
);
    // Internal connections
    wire [2:0] parity_bits;
    wire [3:0] data_bits;
    
    // Instantiate data placement submodule
    data_placement u_data_placement (
        .data_in  (data_in),
        .data_out (data_bits)
    );
    
    // Instantiate parity calculation submodule
    parity_calculator u_parity_calculator (
        .data_in     (data_in),
        .parity_bits (parity_bits)
    );
    
    // Combine outputs to form the encoded word
    encoded_assembler u_encoded_assembler (
        .parity_bits (parity_bits),
        .data_bits   (data_bits),
        .encoded     (encoded)
    );
endmodule

//SystemVerilog
module data_placement (
    input  [3:0] data_in,
    output [3:0] data_out
);
    // Place data bits in their correct positions
    // data_out[0] -> encoded[2], data_out[1] -> encoded[4]
    // data_out[2] -> encoded[5], data_out[3] -> encoded[6]
    assign data_out[0] = data_in[0];
    assign data_out[1] = data_in[1];
    assign data_out[2] = data_in[2];
    assign data_out[3] = data_in[3];
endmodule

//SystemVerilog
module parity_calculator (
    input  [3:0] data_in,
    output [2:0] parity_bits
);
    // Optimized intermediate XOR operations
    wire xor_01 = data_in[0] ^ data_in[1];
    wire xor_23 = data_in[2] ^ data_in[3];
    
    // Calculate parity bits with reduced logic depth
    // parity_bits[0] -> encoded[0]
    // parity_bits[1] -> encoded[1]
    // parity_bits[2] -> encoded[3]
    assign parity_bits[0] = xor_01 ^ data_in[3]; // p0
    assign parity_bits[1] = data_in[0] ^ xor_23; // p1
    assign parity_bits[2] = data_in[1] ^ xor_23; // p2
endmodule

//SystemVerilog
module encoded_assembler (
    input  [2:0] parity_bits,
    input  [3:0] data_bits,
    output [6:0] encoded
);
    // Assemble the final encoded word with parity and data bits
    assign encoded[0] = parity_bits[0]; // p0
    assign encoded[1] = parity_bits[1]; // p1
    assign encoded[2] = data_bits[0];   // d0
    assign encoded[3] = parity_bits[2]; // p2
    assign encoded[4] = data_bits[1];   // d1
    assign encoded[5] = data_bits[2];   // d2
    assign encoded[6] = data_bits[3];   // d3
endmodule