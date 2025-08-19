//SystemVerilog
// Top-level module for dual 8-bit LFSR-based random number generator (Pipelined)
module rng_dual_lfsr_17(
    input            clk,
    input            rst,
    output reg [7:0] rnd
);

    // Stage 1: LFSR Feedback Calculation
    wire [7:0] lfsrA_stage1_out;
    wire [7:0] lfsrB_stage1_out;
    wire       feedbackA_stage1;
    wire       feedbackB_stage1;

    // Stage 2: LFSR Register Pipeline
    reg  [7:0] lfsrA_stage2_out;
    reg  [7:0] lfsrB_stage2_out;
    reg        feedbackA_stage2;
    reg        feedbackB_stage2;

    // Stage 3: Output Register Pipeline
    reg  [7:0] rnd_stage3;

    // LFSR A: 8-bit LFSR with feedback taps at bits 7 and 5
    lfsr8_a_pipeline #(
        .INIT(8'hF3)
    ) lfsr_a_inst (
        .clk(clk),
        .rst(rst),
        .feedback_in(feedbackB_stage2),
        .feedback_out(feedbackA_stage1),
        .lfsr_out(lfsrA_stage1_out)
    );

    // LFSR B: 8-bit LFSR with feedback taps at bits 6 and 0
    lfsr8_b_pipeline #(
        .INIT(8'h0D)
    ) lfsr_b_inst (
        .clk(clk),
        .rst(rst),
        .feedback_in(feedbackA_stage2),
        .feedback_out(feedbackB_stage1),
        .lfsr_out(lfsrB_stage1_out)
    );

    // Pipeline Register Stage 2: Register LFSR A output
    always @(posedge clk) begin
        if (rst) begin
            lfsrA_stage2_out  <= 8'b0;
        end else begin
            lfsrA_stage2_out  <= lfsrA_stage1_out;
        end
    end

    // Pipeline Register Stage 2: Register LFSR B output
    always @(posedge clk) begin
        if (rst) begin
            lfsrB_stage2_out  <= 8'b0;
        end else begin
            lfsrB_stage2_out  <= lfsrB_stage1_out;
        end
    end

    // Pipeline Register Stage 2: Register feedbackA_stage2
    always @(posedge clk) begin
        if (rst) begin
            feedbackA_stage2  <= 1'b0;
        end else begin
            feedbackA_stage2  <= feedbackA_stage1;
        end
    end

    // Pipeline Register Stage 2: Register feedbackB_stage2
    always @(posedge clk) begin
        if (rst) begin
            feedbackB_stage2  <= 1'b0;
        end else begin
            feedbackB_stage2  <= feedbackB_stage1;
        end
    end

    // Pipeline Register Stage 3: XOR and output register
    always @(posedge clk) begin
        if (rst) begin
            rnd_stage3 <= 8'b0;
        end else begin
            rnd_stage3 <= lfsrA_stage2_out ^ lfsrB_stage2_out;
        end
    end

    // Output register
    always @(posedge clk) begin
        if (rst) begin
            rnd <= 8'b0;
        end else begin
            rnd <= rnd_stage3;
        end
    end

endmodule

// ---------------------------------------------------------------------------
// 8-bit LFSR A Submodule (Pipelined)
// Feedback taps: bits 7 and 5
// Feedback input comes from LFSR B
// ---------------------------------------------------------------------------
module lfsr8_a_pipeline #(
    parameter [7:0] INIT = 8'hF3
)(
    input        clk,
    input        rst,
    input        feedback_in,
    output       feedback_out,
    output reg [7:0] lfsr_out
);
    reg [7:0] lfsr_reg_stage1;
    reg       feedback_reg_stage1;

    // Combinational feedback calculation
    wire feedback_calc = lfsr_reg_stage1[7] ^ lfsr_reg_stage1[5];

    // Register lfsr_reg_stage1
    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg_stage1    <= INIT;
        end else begin
            lfsr_reg_stage1    <= {lfsr_reg_stage1[6:0], feedback_in};
        end
    end

    // Register feedback_reg_stage1
    always @(posedge clk) begin
        if (rst) begin
            feedback_reg_stage1 <= 1'b0;
        end else begin
            feedback_reg_stage1 <= feedback_calc;
        end
    end

    // Output assignment
    always @(*) begin
        lfsr_out = lfsr_reg_stage1;
    end
    assign feedback_out = feedback_reg_stage1;

endmodule

// ---------------------------------------------------------------------------
// 8-bit LFSR B Submodule (Pipelined)
// Feedback taps: bits 6 and 0
// Feedback input comes from LFSR A
// ---------------------------------------------------------------------------
module lfsr8_b_pipeline #(
    parameter [7:0] INIT = 8'h0D
)(
    input        clk,
    input        rst,
    input        feedback_in,
    output       feedback_out,
    output reg [7:0] lfsr_out
);
    reg [7:0] lfsr_reg_stage1;
    reg       feedback_reg_stage1;

    // Combinational feedback calculation
    wire feedback_calc = lfsr_reg_stage1[6] ^ lfsr_reg_stage1[0];

    // Register lfsr_reg_stage1
    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg_stage1    <= INIT;
        end else begin
            lfsr_reg_stage1    <= {lfsr_reg_stage1[6:0], feedback_in};
        end
    end

    // Register feedback_reg_stage1
    always @(posedge clk) begin
        if (rst) begin
            feedback_reg_stage1 <= 1'b0;
        end else begin
            feedback_reg_stage1 <= feedback_calc;
        end
    end

    // Output assignment
    always @(*) begin
        lfsr_out = lfsr_reg_stage1;
    end
    assign feedback_out = feedback_reg_stage1;

endmodule