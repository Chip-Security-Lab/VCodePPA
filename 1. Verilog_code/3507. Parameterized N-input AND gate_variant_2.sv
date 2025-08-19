//SystemVerilog
// Top-level module: 8-bit Parallel Prefix Subtractor
module and_gate_n #(
    parameter N = 8  // Fixed to 8-bit for parallel prefix subtractor
) (
    input wire [N-1:0] a,  // N-bit input A (minuend)
    input wire [N-1:0] b,  // N-bit input B (subtrahend)
    output wire [N-1:0] y  // N-bit output Y (difference)
);
    // Instantiate the parallel prefix subtractor
    parallel_prefix_subtractor #(
        .WIDTH(N)
    ) subtractor_inst (
        .minuend(a),
        .subtrahend(b),
        .difference(y)
    );
    
endmodule

// Parallel Prefix Subtractor
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] minuend,      // a
    input wire [WIDTH-1:0] subtrahend,   // b
    output wire [WIDTH-1:0] difference   // result
);
    // Internal signals
    wire [WIDTH-1:0] b_complement;       // One's complement of b
    wire [WIDTH:0] carry;                // Carry signals with extra bit for initial carry-in
    wire [WIDTH-1:0] propagate;          // Propagate signals
    wire [WIDTH-1:0] generate_sig;       // Generate signals
    
    // Level signals for the prefix computation
    wire [WIDTH-1:0] p_level1, p_level2, p_level3;
    wire [WIDTH-1:0] g_level1, g_level2, g_level3;
    
    // Take one's complement of subtrahend
    assign b_complement = ~subtrahend;
    
    // Initial carry-in for subtraction (a - b = a + ~b + 1)
    assign carry[0] = 1'b1;
    
    // Generate propagate and generate signals for each bit
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : pg_signals
            assign propagate[i] = minuend[i] | b_complement[i];
            assign generate_sig[i] = minuend[i] & b_complement[i];
        end
    endgenerate
    
    // Level 1: Combine adjacent pairs (Kogge-Stone algorithm)
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : level1
            if (i == 0) begin
                assign p_level1[i] = propagate[i];
                assign g_level1[i] = generate_sig[i];
            end else begin
                assign p_level1[i] = propagate[i] & propagate[i-1];
                assign g_level1[i] = generate_sig[i] | (propagate[i] & generate_sig[i-1]);
            end
        end
    endgenerate
    
    // Level 2: Combine with stride 2
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : level2
            if (i < 2) begin
                assign p_level2[i] = p_level1[i];
                assign g_level2[i] = g_level1[i];
            end else begin
                assign p_level2[i] = p_level1[i] & p_level1[i-2];
                assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            end
        end
    endgenerate
    
    // Level 3: Combine with stride 4
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : level3
            if (i < 4) begin
                assign p_level3[i] = p_level2[i];
                assign g_level3[i] = g_level2[i];
            end else begin
                assign p_level3[i] = p_level2[i] & p_level2[i-4];
                assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            end
        end
    endgenerate
    
    // Calculate carries using the prefix results
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_calc
            if (i == 0) begin
                assign carry[i+1] = g_level3[i] | (p_level3[i] & carry[0]);
            end else begin
                assign carry[i+1] = g_level3[i] | (p_level3[i] & carry[i]);
            end
        end
    endgenerate
    
    // Calculate difference bits
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : diff_calc
            assign difference[i] = minuend[i] ^ b_complement[i] ^ carry[i];
        end
    endgenerate
    
endmodule