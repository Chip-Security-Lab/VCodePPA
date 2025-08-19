//SystemVerilog
module rng_hash_15(
    input             clk,
    input             rst_n,
    input             enable,
    output reg [7:0]  out_v
);

    // Stage 1: Feedback calculation stage
    reg [7:0]  stage1_feedback;   // Feedback value for LFSR
    reg [7:0]  stage1_lfsr_in;    // LFSR input to next stage

    // Stage 2: LFSR register update stage
    reg [7:0]  stage2_lfsr;       // Registered output

    // Stage 1: Feedback calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_feedback <= 8'h0;
        end else if (enable) begin
            stage1_feedback <= {7'b0, ^(stage2_lfsr & 8'hA3)};
        end
    end

    // Stage 1: LFSR input calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_lfsr_in <= 8'hD2;
        end else if (enable) begin
            stage1_lfsr_in <= {stage2_lfsr[6:0], ^(stage2_lfsr & 8'hA3)};
        end else begin
            stage1_lfsr_in <= stage2_lfsr;
        end
    end

    // Stage 2: LFSR register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_lfsr <= 8'hD2;
        end else if (enable) begin
            stage2_lfsr <= stage1_lfsr_in;
        end
    end

    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_v <= 8'hD2;
        end else if (enable) begin
            out_v <= stage2_lfsr;
        end
    end

endmodule