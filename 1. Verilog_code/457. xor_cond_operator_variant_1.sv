//SystemVerilog
// Top-level module
module xor_cond_operator(
    input [7:0] a,
    input [7:0] b,
    output [7:0] y
);
    // Signal declarations for connecting sub-modules
    wire [7:0] xor_result;
    
    // Instantiate the XOR operation sub-module
    xor_operation xor_op_inst (
        .operand_a(a),
        .operand_b(b),
        .result(xor_result)
    );
    
    // Connect the output
    assign y = xor_result;
    
endmodule

// Sub-module for XOR bitwise operation
module xor_operation #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] operand_a,
    input [DATA_WIDTH-1:0] operand_b,
    output [DATA_WIDTH-1:0] result
);
    // Implement the XOR operation
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : xor_bit
            // Single-bit XOR for each bit position
            xor_single_bit xor_bit_inst (
                .bit_a(operand_a[i]),
                .bit_b(operand_b[i]),
                .bit_result(result[i])
            );
        end
    endgenerate
    
endmodule

// Lowest-level module for single-bit XOR operation
module xor_single_bit(
    input bit_a,
    input bit_b,
    output reg bit_result
);
    // Internal signals for staged logic evaluation
    reg stage1_not_a;
    reg stage1_not_b;
    reg stage1_nand_ab;
    
    reg stage2_left;
    reg stage2_right;
    
    // Implement single-bit XOR using staged logic evaluation
    always @(*) begin
        // Stage 1: Basic operations
        stage1_not_a = ~bit_a;
        stage1_not_b = ~bit_b;
        stage1_nand_ab = ~(bit_a & bit_b);
        
        // Stage 2: Intermediate results
        stage2_left = stage1_not_a & stage1_nand_ab;
        stage2_right = stage1_not_b & stage1_nand_ab;
        
        // Final stage: Combine intermediate results
        bit_result = stage2_left | stage2_right;
    end
    
endmodule