//SystemVerilog
module NeuralRecovery #(parameter W1=8'h2A, W2=8'hD3) (
    input clk,
    input [7:0] noisy,
    output reg [7:0] clean
);
    // Stage 1: Latch input
    reg [7:0] noisy_stage1;
    always @(posedge clk) begin
        noisy_stage1 <= noisy;
    end

    // Stage 2: First multiplication (noisy * W1) using Dadda multiplier, pipelined
    reg [7:0] noisy_stage2;
    reg [7:0] W1_stage2;
    always @(posedge clk) begin
        noisy_stage2 <= noisy_stage1;
        W1_stage2 <= W1;
    end

    wire [15:0] dadda_mult1_result;
    reg [15:0] partial_mult_stage3;
    DaddaMultiplier16x16 dadda_mult1 (
        .a({8'b0, noisy_stage2}),
        .b({8'b0, W1_stage2}),
        .product(dadda_mult1_result)
    );
    always @(posedge clk) begin
        partial_mult_stage3 <= dadda_mult1_result;
    end

    // Stage 3: Latch hidden layer result
    reg [15:0] hidden_stage4;
    always @(posedge clk) begin
        hidden_stage4 <= partial_mult_stage3;
    end

    // Stage 4: Second multiplication (hidden * W2) using Dadda multiplier, pipelined
    reg [15:0] hidden_stage5;
    reg [7:0] W2_stage5;
    always @(posedge clk) begin
        hidden_stage5 <= hidden_stage4;
        W2_stage5 <= W2;
    end

    wire [15:0] dadda_mult2_result;
    reg [15:0] partial_mult_stage6;
    DaddaMultiplier16x16 dadda_mult2 (
        .a(hidden_stage5),
        .b({8'b0, W2_stage5}),
        .product(dadda_mult2_result)
    );
    always @(posedge clk) begin
        partial_mult_stage6 <= dadda_mult2_result;
    end

    // Stage 5: Latch output layer result
    reg [15:0] output_layer_stage7;
    always @(posedge clk) begin
        output_layer_stage7 <= partial_mult_stage6;
    end

    // Stage 6: Output assignment with thresholding
    always @(posedge clk) begin
        clean <= (output_layer_stage7[15:8] > 8'h80) ? 8'hFF : 8'h00;
    end

endmodule

// Dadda Multiplier for 16x16 bits
module DaddaMultiplier16x16 (
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] product
);
    // Partial product generation
    wire [15:0] pp [15:0];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pp
            assign pp[i] = a & {16{b[i]}};
        end
    endgenerate

    // Dadda Reduction Tree
    // Stage 1
    wire [15:0] sum_s1 [7:0];
    wire [15:0] carry_s1 [7:0];

    assign {carry_s1[0], sum_s1[0]} = {1'b0, pp[0]} + {1'b0, pp[1]};
    assign {carry_s1[1], sum_s1[1]} = {1'b0, pp[2]} + {1'b0, pp[3]};
    assign {carry_s1[2], sum_s1[2]} = {1'b0, pp[4]} + {1'b0, pp[5]};
    assign {carry_s1[3], sum_s1[3]} = {1'b0, pp[6]} + {1'b0, pp[7]};
    assign {carry_s1[4], sum_s1[4]} = {1'b0, pp[8]} + {1'b0, pp[9]};
    assign {carry_s1[5], sum_s1[5]} = {1'b0, pp[10]} + {1'b0, pp[11]};
    assign {carry_s1[6], sum_s1[6]} = {1'b0, pp[12]} + {1'b0, pp[13]};
    assign {carry_s1[7], sum_s1[7]} = {1'b0, pp[14]} + {1'b0, pp[15]};

    // Stage 2
    wire [15:0] sum_s2 [3:0];
    wire [15:0] carry_s2 [3:0];

    assign {carry_s2[0], sum_s2[0]} = {1'b0, sum_s1[0]} + {1'b0, sum_s1[1]};
    assign {carry_s2[1], sum_s2[1]} = {1'b0, sum_s1[2]} + {1'b0, sum_s1[3]};
    assign {carry_s2[2], sum_s2[2]} = {1'b0, sum_s1[4]} + {1'b0, sum_s1[5]};
    assign {carry_s2[3], sum_s2[3]} = {1'b0, sum_s1[6]} + {1'b0, sum_s1[7]};

    // Stage 3
    wire [15:0] sum_s3 [1:0];
    wire [15:0] carry_s3 [1:0];

    assign {carry_s3[0], sum_s3[0]} = {1'b0, sum_s2[0]} + {1'b0, sum_s2[1]};
    assign {carry_s3[1], sum_s3[1]} = {1'b0, sum_s2[2]} + {1'b0, sum_s2[3]};

    // Stage 4
    wire [15:0] sum_s4;
    wire [15:0] carry_s4;

    assign {carry_s4, sum_s4} = {1'b0, sum_s3[0]} + {1'b0, sum_s3[1]};

    // Final summation with all carry outs
    wire [17:0] final_sum;
    assign final_sum = {2'b0, sum_s4} + 
                       {1'b0, carry_s4, 1'b0} + 
                       {1'b0, carry_s3[0], 3'b0} + 
                       {1'b0, carry_s3[1], 3'b0} + 
                       {1'b0, carry_s2[0], 7'b0} + 
                       {1'b0, carry_s2[1], 7'b0} + 
                       {1'b0, carry_s2[2], 7'b0} + 
                       {1'b0, carry_s2[3], 7'b0} + 
                       {1'b0, carry_s1[0], 15'b0} + 
                       {1'b0, carry_s1[1], 15'b0} + 
                       {1'b0, carry_s1[2], 15'b0} + 
                       {1'b0, carry_s1[3], 15'b0} + 
                       {1'b0, carry_s1[4], 15'b0} + 
                       {1'b0, carry_s1[5], 15'b0} + 
                       {1'b0, carry_s1[6], 15'b0} + 
                       {1'b0, carry_s1[7], 15'b0};

    assign product = final_sum[15:0];

endmodule