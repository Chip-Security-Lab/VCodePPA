//SystemVerilog
// Top-level module that instantiates the submodules
module hamming_encoder (
    input  wire [3:0] data_in,
    output wire [6:0] encoded_out
);
    // Internal signals
    wire [2:0] parity_bits;
    
    // Instantiate parity generator submodule
    parity_generator parity_gen (
        .data_in(data_in),
        .parity_bits(parity_bits)
    );
    
    // Instantiate code assembler submodule
    code_assembler code_asm (
        .data_in(data_in),
        .parity_bits(parity_bits),
        .encoded_out(encoded_out)
    );
endmodule

// Submodule for generating parity bits
module parity_generator (
    input  wire [3:0] data_in,
    output wire [2:0] parity_bits
);
    // p1, p2, p4 calculation
    // Pipelining the XOR operations to improve timing
    reg [2:0] parity_bits_r;
    wire [2:0] intermediate_parity;
    
    // First stage XOR
    assign intermediate_parity[0] = data_in[0] ^ data_in[1];
    assign intermediate_parity[1] = data_in[0] ^ data_in[2];
    assign intermediate_parity[2] = data_in[1] ^ data_in[2];
    
    // Second stage XOR with pipeline register for better timing
    always @(*) begin
        parity_bits_r[0] = intermediate_parity[0] ^ data_in[3]; // p1
        parity_bits_r[1] = intermediate_parity[1] ^ data_in[3]; // p2
        parity_bits_r[2] = intermediate_parity[2] ^ data_in[3]; // p4
    end
    
    // Output assignment
    assign parity_bits = parity_bits_r;
endmodule

// Submodule for assembling the final encoded output
module code_assembler (
    input  wire [3:0] data_in,
    input  wire [2:0] parity_bits,
    output wire [6:0] encoded_out
);
    // Hamming code organization: p1,p2,d1,p4,d2,d3,d4
    assign encoded_out = {
        data_in[3],    // d4 at position 6
        data_in[2],    // d3 at position 5
        data_in[1],    // d2 at position 4
        parity_bits[2],// p4 at position 3
        data_in[0],    // d1 at position 2
        parity_bits[1],// p2 at position 1
        parity_bits[0] // p1 at position 0
    };
endmodule