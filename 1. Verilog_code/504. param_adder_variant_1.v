module param_adder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b,
    output [WIDTH:0] sum
);

    // Generate and Propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g_stage1, p_stage1;
    wire [WIDTH-1:0] g_stage2, p_stage2;
    wire [WIDTH-1:0] g_stage3, p_stage3;
    wire [WIDTH-1:0] carry;

    // Generate initial G and P signals
    assign g = a & b;
    assign p = a ^ b;

    // Stage 1: Distance 1
    assign g_stage1[0] = g[0];
    assign p_stage1[0] = p[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : stage1
            assign g_stage1[i] = g[i] | (p[i] & g[i-1]);
            assign p_stage1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Stage 2: Distance 2
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[1] = p_stage1[1];
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin : stage2
            assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
            assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
        end
    endgenerate

    // Stage 3: Distance 4
    assign g_stage3[0] = g_stage2[0];
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[1] = g_stage2[1];
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[2] = g_stage2[2];
    assign p_stage3[2] = p_stage2[2];
    assign g_stage3[3] = g_stage2[3];
    assign p_stage3[3] = p_stage2[3];
    generate
        for (i = 4; i < WIDTH; i = i + 1) begin : stage3
            assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-4]);
            assign p_stage3[i] = p_stage2[i] & p_stage2[i-4];
        end
    endgenerate

    // Generate carry signals
    assign carry[0] = 1'b0;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : carry_gen
            assign carry[i] = g_stage3[i-1];
        end
    endgenerate

    // Calculate final sum
    assign sum[0] = p[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : sum_gen
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
    assign sum[WIDTH] = g_stage3[WIDTH-1];

endmodule