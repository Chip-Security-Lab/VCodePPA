//SystemVerilog
// Top-level module
module async_block_cipher #(
    parameter BLOCK_SIZE = 16
) (
    input  wire [BLOCK_SIZE-1:0] plaintext, key,
    output wire [BLOCK_SIZE-1:0] ciphertext
);
    // Internal signals for data flow between stages
    wire [BLOCK_SIZE-1:0] intermediate;
    
    // Instantiate initial key mixing layer
    key_mixing_layer #(
        .BLOCK_SIZE(BLOCK_SIZE)
    ) key_mixer (
        .data_in(plaintext),
        .key(key),
        .data_out(intermediate)
    );
    
    // Instantiate enhanced substitution processing
    enhanced_substitution #(
        .BLOCK_SIZE(BLOCK_SIZE)
    ) sub_processor (
        .data_in(intermediate),
        .data_out(ciphertext)
    );
    
endmodule

// Layer 1: Key Mixing with configurable operation
module key_mixing_layer #(
    parameter BLOCK_SIZE = 16
) (
    input  wire [BLOCK_SIZE-1:0] data_in,
    input  wire [BLOCK_SIZE-1:0] key,
    output wire [BLOCK_SIZE-1:0] data_out
);
    // Simple XOR operation with the key
    assign data_out = data_in ^ key;
endmodule

// Enhanced substitution processing with sub-modules
module enhanced_substitution #(
    parameter BLOCK_SIZE = 16
) (
    input  wire [BLOCK_SIZE-1:0] data_in,
    output wire [BLOCK_SIZE-1:0] data_out
);
    // Internal signals for each substitution unit
    wire [BLOCK_SIZE-1:0] sub_results;
    
    // Instantiate the substitution calculator
    substitution_calculator #(
        .BLOCK_SIZE(BLOCK_SIZE)
    ) sub_calc (
        .data_in(data_in),
        .sub_results(sub_results)
    );
    
    // Instantiate the output formatter
    substitution_formatter #(
        .BLOCK_SIZE(BLOCK_SIZE)
    ) sub_format (
        .sub_results(sub_results),
        .data_out(data_out)
    );
endmodule

// Module for performing the actual substitution calculations
module substitution_calculator #(
    parameter BLOCK_SIZE = 16
) (
    input  wire [BLOCK_SIZE-1:0] data_in,
    output wire [BLOCK_SIZE-1:0] sub_results
);
    genvar i;
    generate
        for (i = 0; i < BLOCK_SIZE/4; i = i + 1) begin : sub_calc_blocks
            // Calculate index for the next 4-bit chunk with proper wrapping
            localparam next_index = (i+1) % (BLOCK_SIZE/4);
            
            // Instantiate individual substitution unit with conditional inverse subtractor
            substitution_unit sub_unit (
                .current_chunk(data_in[i*4+:4]),
                .next_chunk(data_in[next_index*4+:4]),
                .result(sub_results[i*4+:4])
            );
        end
    endgenerate
endmodule

// Small atomic substitution unit for 4-bit chunks with conditional inverse subtractor
module substitution_unit (
    input  wire [3:0] current_chunk,
    input  wire [3:0] next_chunk,
    output wire [3:0] result
);
    // Internal signals for conditional inverse subtractor
    wire subtraction_mode;
    wire [3:0] operand_a, operand_b;
    wire [3:0] inverted_b;
    wire [4:0] sum_with_carry;
    wire carry_in;
    
    // Determine subtraction mode based on MSB of current_chunk
    assign subtraction_mode = current_chunk[3];
    
    // Select operands based on subtraction mode
    assign operand_a = current_chunk;
    assign operand_b = next_chunk;
    
    // Conditionally invert the second operand for subtraction
    assign inverted_b = subtraction_mode ? ~operand_b : operand_b;
    
    // Set carry_in to 1 for subtraction (adding 1 to complete two's complement)
    assign carry_in = subtraction_mode;
    
    // Perform addition with potential inversion and carry
    assign sum_with_carry = operand_a + inverted_b + carry_in;
    
    // Final 4-bit result
    assign result = sum_with_carry[3:0];
endmodule

// Module to format the final substitution output
module substitution_formatter #(
    parameter BLOCK_SIZE = 16
) (
    input  wire [BLOCK_SIZE-1:0] sub_results,
    output wire [BLOCK_SIZE-1:0] data_out
);
    // Direct connection in this implementation
    // Can be extended for additional formatting operations
    assign data_out = sub_results;
endmodule