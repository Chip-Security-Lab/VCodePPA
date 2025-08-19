//SystemVerilog
module AreaOptimized_Hamming(
    input [3:0] din,
    output [6:0] code
);
    wire [2:0] parity_bits;
    wire [3:0] data_bits;
    
    // Instantiate parity generator module
    ParityGenerator parity_gen (
        .din(din),
        .parity_bits(parity_bits)
    );
    
    // Instantiate data bits passthrough module
    DataBitsPassthrough data_passthrough (
        .din(din),
        .data_bits(data_bits)
    );
    
    // Connect parity and data bits to form complete Hamming code
    CodeAssembler code_assembler (
        .parity_bits(parity_bits),
        .data_bits(data_bits),
        .code(code)
    );
endmodule

module ParityGenerator(
    input [3:0] din,
    output [2:0] parity_bits
);
    // P1, P2, P4 parity bits calculation
    assign parity_bits[0] = din[0] ^ din[1] ^ din[3]; // P1
    assign parity_bits[1] = din[0] ^ din[2] ^ din[3]; // P2
    assign parity_bits[2] = din[1] ^ din[2] ^ din[3]; // P4
endmodule

module DataBitsPassthrough(
    input [3:0] din,
    output [3:0] data_bits
);
    // Pass through data bits (D3, D5, D6, D7)
    assign data_bits = din;
endmodule

module CodeAssembler(
    input [2:0] parity_bits,
    input [3:0] data_bits,
    output [6:0] code
);
    // Assemble the complete Hamming code
    // Format: [P1, P2, D3, P4, D5, D6, D7]
    assign code[0] = parity_bits[0];     // P1
    assign code[1] = parity_bits[1];     // P2
    assign code[2] = data_bits[0];       // D3
    assign code[3] = parity_bits[2];     // P4
    assign code[4] = data_bits[1];       // D5
    assign code[5] = data_bits[2];       // D6
    assign code[6] = data_bits[3];       // D7
endmodule