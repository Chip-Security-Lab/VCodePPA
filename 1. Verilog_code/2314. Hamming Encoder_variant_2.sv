//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module hamming_encoder #(
    parameter DATA_WIDTH = 4,
    parameter CODE_WIDTH = 7
) (
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [CODE_WIDTH-1:0] encoded
);
    // Internal connections
    logic [2:0] parity_bits;
    
    // Instantiate optimized submodules
    parity_calculator parity_calc_inst (
        .data_in(data_in),
        .parity_bits(parity_bits)
    );
    
    encoding_formatter encode_format_inst (
        .data_in(data_in),
        .parity_bits(parity_bits),
        .encoded_out(encoded)
    );
endmodule

// Optimized parity calculation module with clearer implementation
module parity_calculator #(
    parameter DATA_WIDTH = 4
) (
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [2:0] parity_bits
);
    // Calculate all parity bits in parallel using XOR operations
    // Optimized for resource sharing and reduced logic depth
    always_comb begin
        // P0: checks positions 1,3,5,7 (data_in[0,1,3])
        parity_bits[0] = ^{data_in[0], data_in[1], data_in[3]};
        
        // P1: checks positions 2,3,6,7 (data_in[0,2,3])
        parity_bits[1] = ^{data_in[0], data_in[2], data_in[3]};
        
        // P2: checks positions 4,5,6,7 (data_in[1,2,3])
        parity_bits[2] = ^{data_in[1], data_in[2], data_in[3]};
    end
endmodule

// Enhanced encoding formatter with parameterized structure
module encoding_formatter #(
    parameter DATA_WIDTH = 4,
    parameter CODE_WIDTH = 7
) (
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic [2:0] parity_bits,
    output logic [CODE_WIDTH-1:0] encoded_out
);
    // Map data and parity bits into Hamming code format
    // Optimized for timing with reduced fanout
    always_comb begin
        // Organized placement of parity and data bits
        // P0, P1, D0, P2, D1, D2, D3
        encoded_out = {
            data_in[3],    // Position 7 (MSB)
            data_in[2],    // Position 6
            data_in[1],    // Position 5
            parity_bits[2],// Position 4
            data_in[0],    // Position 3
            parity_bits[1],// Position 2
            parity_bits[0] // Position 1 (LSB)
        };
    end
endmodule