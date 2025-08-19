//SystemVerilog
module parity_checker #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_in,
    input  wire             parity_in,
    input  wire             odd_parity_mode,
    output wire             error_flag
);
    // Optimized parity check using tree-based XOR reduction
    wire [WIDTH/2-1:0] xor_level1;
    wire [WIDTH/4-1:0] xor_level2;
    wire [WIDTH/8-1:0] xor_level3;
    wire [WIDTH/16-1:0] xor_level4;
    wire parity_calc;

    // First level XOR reduction
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin
            assign xor_level1[i] = data_in[2*i] ^ data_in[2*i+1];
        end
    endgenerate

    // Second level XOR reduction
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin
            assign xor_level2[i] = xor_level1[2*i] ^ xor_level1[2*i+1];
        end
    endgenerate

    // Third level XOR reduction
    generate
        for (i = 0; i < WIDTH/8; i = i + 1) begin
            assign xor_level3[i] = xor_level2[2*i] ^ xor_level2[2*i+1];
        end
    endgenerate

    // Fourth level XOR reduction
    generate
        for (i = 0; i < WIDTH/16; i = i + 1) begin
            assign xor_level4[i] = xor_level3[2*i] ^ xor_level3[2*i+1];
        end
    endgenerate

    // Final XOR reduction
    assign parity_calc = ^xor_level4;
    assign error_flag = parity_calc ^ parity_in ^ odd_parity_mode;
endmodule