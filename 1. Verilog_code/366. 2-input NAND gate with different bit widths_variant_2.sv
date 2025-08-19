//SystemVerilog
// Top-level module
module nand2_9 (
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [3:0] Y
);
    // Instance of parallel prefix adder module instead of NAND processor
    parallel_prefix_adder bit_processor (
        .a_in(A),
        .b_in(B),
        .sum(Y)
    );
endmodule

// Parallel Prefix Adder implementation (Kogge-Stone architecture)
module parallel_prefix_adder #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a_in,
    input wire [WIDTH-1:0] b_in,
    output wire [WIDTH-1:0] sum
);
    // Generate propagate and generate signals
    wire [WIDTH-1:0] p; // Propagate signals
    wire [WIDTH-1:0] g; // Generate signals
    
    // Final carry signals
    wire [WIDTH:0] c;
    
    // Stage 1 - Generate initial p and g values
    generate_pg_signals pg_gen(
        .a(a_in),
        .b(b_in),
        .p(p),
        .g(g)
    );
    
    // Stage 2 - Parallel prefix computation of carries
    kogge_stone_prefix prefix_network(
        .p(p),
        .g(g),
        .cin(1'b0),  // Assuming no carry in
        .cout(c)
    );
    
    // Stage 3 - Compute sum bits
    assign sum = p ^ c[WIDTH-1:0];
endmodule

// Generate propagate and generate signals
module generate_pg_signals #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] p,
    output wire [WIDTH-1:0] g
);
    // Propagate: p_i = a_i XOR b_i
    // Generate: g_i = a_i AND b_i
    assign p = a ^ b;
    assign g = a & b;
endmodule

// Kogge-Stone parallel prefix network
module kogge_stone_prefix #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] p,
    input wire [WIDTH-1:0] g,
    input wire cin,
    output wire [WIDTH:0] cout
);
    // Intermediate signals for prefix computation
    wire [WIDTH-1:0] p_stage1, g_stage1;
    wire [WIDTH-1:0] p_stage2, g_stage2;
    
    // Set initial carry-in
    assign cout[0] = cin;
    
    // First stage prefix computation
    // For Kogge-Stone, each stage combines pairs at distance 2^(stage-1)
    
    // Stage 1: Distance 1
    // First bit is special case with carry-in
    assign g_stage1[0] = g[0] | (p[0] & cin);
    assign p_stage1[0] = p[0];
    
    // Other bits in stage 1
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : stage1_prefix
            assign g_stage1[i] = g[i] | (p[i] & g[i-1]);
            assign p_stage1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Stage 2: Distance 2
    // For 4-bit adder, we only need 2 stages
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[1] = p_stage1[1];
    
    // Bits 2 and 3 combine with bits 0 and 1
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin : stage2_prefix
            assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
            assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
        end
    endgenerate
    
    // Final carry outputs
    assign cout[1] = g_stage2[0];
    assign cout[2] = g_stage2[1];
    assign cout[3] = g_stage2[2];
    assign cout[4] = g_stage2[3];
endmodule