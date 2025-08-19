//SystemVerilog
module async_onehot_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] priority_onehot,
    output valid
);

    // Parallel prefix network for priority encoding
    wire [WIDTH-1:0] prefix_or;
    wire [WIDTH-1:0] prefix_and;
    
    // First level - generate propagate and generate signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign prefix_or[i] = data_in[i];
            assign prefix_and[i] = ~data_in[i];
        end
    endgenerate

    // Parallel prefix computation
    wire [WIDTH-1:0] stage1_or, stage1_and;
    wire [WIDTH-1:0] stage2_or, stage2_and;
    wire [WIDTH-1:0] stage3_or, stage3_and;

    // Stage 1
    assign stage1_or[0] = prefix_or[0];
    assign stage1_and[0] = prefix_and[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign stage1_or[i] = prefix_or[i] | prefix_or[i-1];
            assign stage1_and[i] = prefix_and[i] & prefix_and[i-1];
        end
    endgenerate

    // Stage 2
    assign stage2_or[0] = stage1_or[0];
    assign stage2_and[0] = stage1_and[0];
    assign stage2_or[1] = stage1_or[1];
    assign stage2_and[1] = stage1_and[1];
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin
            assign stage2_or[i] = stage1_or[i] | stage1_or[i-2];
            assign stage2_and[i] = stage1_and[i] & stage1_and[i-2];
        end
    endgenerate

    // Stage 3
    assign stage3_or[0] = stage2_or[0];
    assign stage3_and[0] = stage2_and[0];
    assign stage3_or[1] = stage2_or[1];
    assign stage3_and[1] = stage2_and[1];
    assign stage3_or[2] = stage2_or[2];
    assign stage3_and[2] = stage2_and[2];
    assign stage3_or[3] = stage2_or[3];
    assign stage3_and[3] = stage2_and[3];
    generate
        for (i = 4; i < WIDTH; i = i + 1) begin
            assign stage3_or[i] = stage2_or[i] | stage2_or[i-4];
            assign stage3_and[i] = stage2_and[i] & stage2_and[i-4];
        end
    endgenerate

    // Generate priority one-hot output
    assign priority_onehot[0] = data_in[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign priority_onehot[i] = data_in[i] & ~stage3_or[i-1];
        end
    endgenerate

    assign valid = |data_in;

endmodule