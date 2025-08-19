//SystemVerilog
module rng_dual_lfsr_17(
    input            clk,
    input            rst,
    output reg [7:0] rnd
);

    // Pipeline Stage 1: State Registers
    reg [7:0] lfsrA_stage1, lfsrB_stage1;

    // Pipeline Stage 2: Feedback Calculation
    reg feedbackA_stage2, feedbackB_stage2;
    reg [7:0] lfsrA_stage2, lfsrB_stage2;

    // Pipeline Stage 3: Next State Calculation
    reg [7:0] nextA_stage3, nextB_stage3;
    reg [7:0] lfsrA_stage3, lfsrB_stage3;

    // Pipeline Stage 4: Output Calculation
    reg [7:0] rnd_stage4;

    // Stage 1: Register current states
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsrA_stage1 <= 8'hF3;
            lfsrB_stage1 <= 8'h0D;
        end else begin
            lfsrA_stage1 <= nextA_stage3;
            lfsrB_stage1 <= nextB_stage3;
        end
    end

    // Stage 2: Calculate feedbacks
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            feedbackA_stage2 <= 1'b0;
            feedbackB_stage2 <= 1'b0;
            lfsrA_stage2     <= 8'hF3;
            lfsrB_stage2     <= 8'h0D;
        end else begin
            feedbackA_stage2 <= lfsrA_stage1[7] ^ lfsrA_stage1[5];
            feedbackB_stage2 <= lfsrB_stage1[6] ^ lfsrB_stage1[0];
            lfsrA_stage2     <= lfsrA_stage1;
            lfsrB_stage2     <= lfsrB_stage1;
        end
    end

    // Stage 3: Calculate next LFSR states
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            nextA_stage3 <= 8'hF3;
            nextB_stage3 <= 8'h0D;
            lfsrA_stage3 <= 8'hF3;
            lfsrB_stage3 <= 8'h0D;
        end else begin
            nextA_stage3 <= {lfsrA_stage2[6:0], feedbackB_stage2};
            nextB_stage3 <= {lfsrB_stage2[6:0], feedbackA_stage2};
            lfsrA_stage3 <= lfsrA_stage2;
            lfsrB_stage3 <= lfsrB_stage2;
        end
    end

    // Stage 4: Output computation (XOR)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rnd_stage4 <= 8'h00;
        end else begin
            rnd_stage4 <= lfsrA_stage3 ^ lfsrB_stage3;
        end
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rnd <= 8'h00;
        end else begin
            rnd <= rnd_stage4;
        end
    end

endmodule