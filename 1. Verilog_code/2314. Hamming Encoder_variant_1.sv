//SystemVerilog
module hamming_encoder (
    input  [3:0] data_in,
    output [6:0] encoded
);
    // Direct mapping of data bits to encoded positions
    assign encoded[2] = data_in[0];
    assign encoded[4] = data_in[1];
    assign encoded[5] = data_in[2];
    assign encoded[6] = data_in[3];
    
    // Optimized parity computation using XOR logic reduction
    // This implementation reduces the gate count and logic depth
    assign encoded[0] = ^{data_in[0], data_in[1], data_in[3]};
    assign encoded[1] = ^{data_in[0], data_in[2], data_in[3]};
    assign encoded[3] = ^{data_in[1], data_in[2], data_in[3]};
endmodule