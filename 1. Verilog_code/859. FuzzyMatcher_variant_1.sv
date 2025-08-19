//SystemVerilog
module FuzzyMatcher #(parameter WIDTH=8, THRESHOLD=2) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output match
);

    // XOR to find different bits
    wire [WIDTH-1:0] xor_result = data ^ pattern;
    
    // Parallel prefix adder implementation for bit counting
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g_level1, p_level1;
    wire [WIDTH-1:0] g_level2, p_level2;
    wire [WIDTH-1:0] g_level3, p_level3;
    wire [WIDTH-1:0] sum;
    
    // Generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign g[i] = xor_result[i];
            assign p[i] = xor_result[i];
        end
    endgenerate
    
    // Level 1
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : level1
            assign g_level1[i] = g[i] | (p[i] & g[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Level 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin : level2
            assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            assign p_level2[i] = p_level1[i] & p_level1[i-2];
        end
    endgenerate
    
    // Level 3
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    generate
        for (i = 4; i < WIDTH; i = i + 1) begin : level3
            assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            assign p_level3[i] = p_level2[i] & p_level2[i-4];
        end
    endgenerate
    
    // Final sum calculation
    assign sum[0] = g_level3[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : final_sum
            assign sum[i] = g_level3[i] ^ p_level3[i-1];
        end
    endgenerate
    
    // Match if the number of different bits is less than or equal to threshold
    assign match = (sum <= THRESHOLD);

endmodule