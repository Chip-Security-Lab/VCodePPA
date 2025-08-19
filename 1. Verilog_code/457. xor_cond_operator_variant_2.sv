//SystemVerilog
// Top level module with parallel prefix adder implementation
module xor_cond_operator(
    input [7:0] a,
    input [7:0] b,
    output [7:0] y
);
    // Internal signals for connecting submodules
    wire [3:0] lower_result;
    wire [3:0] upper_result;
    
    // Instantiate parallel prefix adder submodules for lower and upper nibbles
    parallel_prefix_adder_4bit lower_nibble_adder (
        .a(a[3:0]),
        .b(b[3:0]),
        .sum(lower_result)
    );
    
    parallel_prefix_adder_4bit upper_nibble_adder (
        .a(a[7:4]),
        .b(b[7:4]),
        .sum(upper_result)
    );
    
    // Combine results from submodules
    assign y = {upper_result, lower_result};
endmodule

// 4-bit Parallel Prefix Adder (Kogge-Stone implementation)
module parallel_prefix_adder_4bit(
    input [3:0] a,
    input [3:0] b,
    output [3:0] sum
);
    // Generate and propagate signals
    wire [3:0] g, p;
    // Group generate and propagate signals for prefix stages
    wire [3:0] g_stage1, p_stage1;
    wire [3:0] g_stage2, p_stage2;
    
    // Step 1: Generate initial generate and propagate signals
    assign g = a & b;           // Generate
    assign p = a ^ b;           // Propagate
    
    // Step 2: Prefix stage 1 - compute carry propagation across 1-bit boundaries
    // g_stage1[i] = g[i] | (p[i] & g[i-1])
    assign g_stage1[0] = g[0];
    assign p_stage1[0] = p[0];
    
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    assign p_stage1[1] = p[1] & p[0];
    
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    assign p_stage1[2] = p[2] & p[1];
    
    assign g_stage1[3] = g[3] | (p[3] & g[2]);
    assign p_stage1[3] = p[3] & p[2];
    
    // Step 3: Prefix stage 2 - compute carry propagation across 2-bit boundaries
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[0] = p_stage1[0];
    
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[1] = p_stage1[1];
    
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    assign p_stage2[3] = p_stage1[3] & p_stage1[1];
    
    // Step 4: Compute actual carries
    wire [3:0] c;
    assign c[0] = 0;  // No carry-in
    assign c[1] = g_stage2[0];
    assign c[2] = g_stage2[1];
    assign c[3] = g_stage2[2];
    
    // Step 5: Final sum computation
    assign sum = p ^ c;
    
endmodule

// 8-bit Parallel Prefix Adder module (not directly used but available for future expansion)
module parallel_prefix_adder_8bit(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    // Generate and propagate signals
    wire [7:0] g, p;
    // Multi-stage prefix network signals
    wire [7:0] g_stage1, p_stage1;
    wire [7:0] g_stage2, p_stage2;
    wire [7:0] g_stage3, p_stage3;
    
    // Step 1: Initial generate and propagate computation
    assign g = a & b;           // Generate
    assign p = a ^ b;           // Propagate
    
    // Step 2: Stage 1 - distance 1 prefix computation
    assign g_stage1[0] = g[0];
    assign p_stage1[0] = p[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : stage1_gen
            assign g_stage1[i] = g[i] | (p[i] & g[i-1]);
            assign p_stage1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Step 3: Stage 2 - distance 2 prefix computation
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[1] = p_stage1[1];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin : stage2_gen
            assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
            assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
        end
    endgenerate
    
    // Step 4: Stage 3 - distance 4 prefix computation
    assign g_stage3[0] = g_stage2[0];
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[1] = g_stage2[1];
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[2] = g_stage2[2];
    assign p_stage3[2] = p_stage2[2];
    assign g_stage3[3] = g_stage2[3];
    assign p_stage3[3] = p_stage2[3];
    
    generate
        for (i = 4; i < 8; i = i + 1) begin : stage3_gen
            assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-4]);
            assign p_stage3[i] = p_stage2[i] & p_stage2[i-4];
        end
    endgenerate
    
    // Step 5: Compute carries
    wire [7:0] c;
    assign c[0] = 0;  // No carry-in
    
    generate
        for (i = 1; i < 8; i = i + 1) begin : carry_gen
            assign c[i] = g_stage3[i-1];
        end
    endgenerate
    
    // Step 6: Final sum computation
    assign sum = p ^ c;
    
endmodule