//SystemVerilog
module one_hot_comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] one_hot_a,     // One-hot encoded input A
    input [WIDTH-1:0] one_hot_b,     // One-hot encoded input B
    output valid_one_hot_a,          // Checks if A is valid one-hot
    output valid_one_hot_b,          // Checks if B is valid one-hot
    output equal_states,             // True if both represent the same state
    output [WIDTH-1:0] common_states // Bitwise AND showing common active bits
);
    // Using Han-Carlson adder algorithm for popcount
    wire [WIDTH:0] sum_a, sum_b;
    
    // Han-Carlson adder for counting bits in one_hot_a
    han_carlson_adder #(
        .WIDTH(WIDTH)
    ) adder_a (
        .a({1'b0, one_hot_a}),       // Add zero as MSB
        .b({WIDTH+1{1'b0}}),         // No carry input needed
        .sum(sum_a)                  // Result of popcount
    );
    
    // Han-Carlson adder for counting bits in one_hot_b
    han_carlson_adder #(
        .WIDTH(WIDTH)
    ) adder_b (
        .a({1'b0, one_hot_b}),       // Add zero as MSB
        .b({WIDTH+1{1'b0}}),         // No carry input needed
        .sum(sum_b)                  // Result of popcount
    );
    
    // Valid one-hot check - exactly one bit should be set
    assign valid_one_hot_a = (sum_a[WIDTH:0] == {{WIDTH{1'b0}}, 1'b1});
    assign valid_one_hot_b = (sum_b[WIDTH:0] == {{WIDTH{1'b0}}, 1'b1});
    
    // Common states (bitwise AND)
    assign common_states = one_hot_a & one_hot_b;
    
    // Equal states - either they are the same or they have common set bits
    assign equal_states = (one_hot_a == one_hot_b) || (|common_states);
endmodule

module han_carlson_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH:0] a,
    input [WIDTH:0] b,
    output [WIDTH:0] sum
);
    // Pre-computation stage
    wire [WIDTH:0] p, g;           // Propagate and generate signals
    wire [WIDTH:0] c;              // Carry signals
    
    // Generate p and g signals
    genvar i;
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : pg_gen
            assign p[i] = a[i] ^ b[i];  // Propagate
            assign g[i] = a[i] & b[i];  // Generate
        end
    endgenerate
    
    // Han-Carlson parallel prefix computation
    // First stage - compute for even indices
    wire [WIDTH:0] g_even_1, p_even_1;
    
    generate
        // Handle bit 0 separately
        assign g_even_1[0] = g[0];
        assign p_even_1[0] = p[0];
        
        for (i = 2; i <= WIDTH; i = i + 2) begin : stage1_even
            assign g_even_1[i] = g[i] | (p[i] & g[i-1]);
            assign p_even_1[i] = p[i] & p[i-1];
        end
        
        // Pass through odd indices
        for (i = 1; i <= WIDTH; i = i + 2) begin : stage1_odd_passthrough
            assign g_even_1[i] = g[i];
            assign p_even_1[i] = p[i];
        end
    endgenerate
    
    // Second stage - compute for all even indices with distance 2
    wire [WIDTH:0] g_even_2, p_even_2;
    
    generate
        // Handle bits 0 and 2 separately
        assign g_even_2[0] = g_even_1[0];
        assign p_even_2[0] = p_even_1[0];
        if (WIDTH >= 2) begin
            assign g_even_2[2] = g_even_1[2];
            assign p_even_2[2] = p_even_1[2];
        end
        
        for (i = 4; i <= WIDTH; i = i + 2) begin : stage2_even
            assign g_even_2[i] = g_even_1[i] | (p_even_1[i] & g_even_1[i-2]);
            assign p_even_2[i] = p_even_1[i] & p_even_1[i-2];
        end
        
        // Pass through odd indices
        for (i = 1; i <= WIDTH; i = i + 2) begin : stage2_odd_passthrough
            assign g_even_2[i] = g_even_1[i];
            assign p_even_2[i] = p_even_1[i];
        end
    endgenerate
    
    // Third stage - compute final values for odd indices
    wire [WIDTH:0] g_final, p_final;
    
    generate
        // Direct assignment for even indices
        for (i = 0; i <= WIDTH; i = i + 2) begin : stage3_even_passthrough
            assign g_final[i] = g_even_2[i];
            assign p_final[i] = p_even_2[i];
        end
        
        // Compute for odd indices
        for (i = 1; i <= WIDTH; i = i + 2) begin : stage3_odd
            assign g_final[i] = g_even_2[i] | (p_even_2[i] & g_final[i-1]);
            assign p_final[i] = p_even_2[i] & p_final[i-1];
        end
    endgenerate
    
    // Assign carries
    assign c[0] = 1'b0;  // No carry input
    
    generate
        for (i = 1; i <= WIDTH; i = i + 1) begin : carry_assign
            assign c[i] = g_final[i-1];
        end
    endgenerate
    
    // Final sum computation
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : sum_computation
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule