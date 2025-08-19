//SystemVerilog
module parity_generator #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_i,
    input  wire             odd_parity,  // 0=even, 1=odd
    output wire             parity_bit
);
    // Implement parity calculation using a more structured approach
    // that can be better optimized by synthesis tools
    
    // Internal signals for multi-level parity calculation
    wire [WIDTH/2-1:0] level1_parity;
    wire [WIDTH/4-1:0] level2_parity;
    wire [WIDTH/8-1:0] level3_parity;
    
    // First level parity calculation (combine pairs of bits)
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : LEVEL1_GEN
            assign level1_parity[i] = data_i[i*2] ^ data_i[i*2+1];
        end
    endgenerate
    
    // Second level parity calculation
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin : LEVEL2_GEN
            assign level2_parity[i] = level1_parity[i*2] ^ level1_parity[i*2+1];
        end
    endgenerate
    
    // Final level parity calculation
    assign level3_parity[0] = level2_parity[0] ^ level2_parity[1];
    
    // Adjust for odd/even selection
    assign parity_bit = level3_parity[0] ^ odd_parity;
endmodule