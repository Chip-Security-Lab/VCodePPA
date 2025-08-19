//SystemVerilog
// Top level module
module SelfCheck_NAND (
    input wire a, b,
    output wire y,
    output wire parity
);
    // Internal wire connecting submodules
    wire nand_result;
    
    // Instantiate functional submodules
    NAND_Logic nand_logic_inst (
        .in_a(a),
        .in_b(b),
        .out_y(nand_result)
    );
    
    // Connect the NAND output to the module output
    assign y = nand_result;
    
    Parity_Generator parity_gen_inst (
        .in_a(a),
        .in_b(b),
        .in_y(nand_result),
        .out_parity(parity)
    );
    
endmodule

// NAND logic submodule
module NAND_Logic (
    input wire in_a, in_b,
    output wire out_y
);
    // Implement basic NAND logic
    // Two-stage implementation for better timing characteristics
    wire and_result;
    
    // First stage: AND operation
    assign and_result = in_a & in_b;
    
    // Second stage: NOT operation
    assign out_y = ~and_result;
    
endmodule

// Parity generation submodule
module Parity_Generator (
    input wire in_a, in_b, in_y,
    output wire out_parity
);
    // Generate parity bit using XOR tree implementation for better performance
    // This structure allows for better fan-out and timing control
    wire intermediate_xor;
    
    // First XOR operation
    assign intermediate_xor = in_a ^ in_b;
    
    // Second XOR operation
    assign out_parity = intermediate_xor ^ in_y;
    
endmodule