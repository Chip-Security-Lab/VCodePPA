//SystemVerilog
module NeuralRecovery #(parameter W1=8'h2A, W2=8'hD3) (
    input clk,
    input [7:0] noisy,
    output reg [7:0] clean
);

    // Stage 1: Register input
    reg [7:0] noisy_stage1;
    // Stage 2: Partial multiplications
    reg [7:0] partial_mul1_stage2;
    reg [7:0] partial_mul2_stage2;
    reg [7:0] noisy_stage2;
    reg [7:0] w1_stage2;
    // Stage 3: Combine partial multiplications
    reg [15:0] hidden_stage3;
    // Stage 4: Register hidden product
    reg [15:0] hidden_stage4;
    // Stage 5: Partial multiplication for output layer (lower 8 bits)
    reg [15:0] output_partial_stage5;
    reg [15:0] hidden_stage5;
    reg [7:0] w2_stage5;
    // Stage 6: Partial multiplication for output layer (upper 8 bits)
    reg [15:0] output_partial_stage6;
    // Stage 7: Combine partial results for final output_layer
    reg [15:0] output_layer_stage7;

    // -------------------------------------------------------------------------
    // Stage 1: Register input noisy to noisy_stage1
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        noisy_stage1 <= noisy;
    end

    // -------------------------------------------------------------------------
    // Stage 2.1: Calculate partial_mul1_stage2 (lower 4 bits)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        partial_mul1_stage2 <= noisy_stage1[3:0] * W1[3:0];
    end

    // -------------------------------------------------------------------------
    // Stage 2.2: Calculate partial_mul2_stage2 (upper 4 bits)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        partial_mul2_stage2 <= noisy_stage1[7:4] * W1[7:4];
    end

    // -------------------------------------------------------------------------
    // Stage 2.3: Register noisy_stage1 and W1 for pipelining
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        noisy_stage2 <= noisy_stage1;
        w1_stage2    <= W1;
    end

    // -------------------------------------------------------------------------
    // Stage 3: Combine partial multiplications for full product
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        hidden_stage3 <= ({8'b0, partial_mul2_stage2} << 4) | {8'b0, partial_mul1_stage2};
    end

    // -------------------------------------------------------------------------
    // Stage 4: Register hidden product for next multiplication
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        hidden_stage4 <= hidden_stage3;
    end

    // -------------------------------------------------------------------------
    // Stage 5.1: Partial multiplication for output layer (lower 8 bits)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        output_partial_stage5 <= hidden_stage4[7:0] * W2;
    end

    // -------------------------------------------------------------------------
    // Stage 5.2: Register hidden_stage4 and W2 for pipelining
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        hidden_stage5 <= hidden_stage4;
        w2_stage5     <= W2;
    end

    // -------------------------------------------------------------------------
    // Stage 6: Partial multiplication for output layer (upper 8 bits)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        output_partial_stage6 <= hidden_stage5[15:8] * w2_stage5;
    end

    // -------------------------------------------------------------------------
    // Stage 7: Combine partial results for final output_layer
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        output_layer_stage7 <= (output_partial_stage6 << 8) + output_partial_stage5;
    end

    // -------------------------------------------------------------------------
    // Stage 8: Output decision logic
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        clean <= (output_layer_stage7[15:8] > 8'h80) ? 8'hFF : 8'h00;
    end

endmodule