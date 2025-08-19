//SystemVerilog
module rng_dual_lfsr_17_pipeline (
    input            clk,
    input            rst,
    output reg [7:0] rnd_out,
    output reg       rnd_valid
);
    // Stage 1 registers and signals
    reg [7:0] sA_stage1, sB_stage1;
    reg       valid_stage1;

    wire feedbackA_stage1 = sA_stage1[7] ^ sA_stage1[5];
    wire feedbackB_stage1 = sB_stage1[6] ^ sB_stage1[0];

    // Stage 2 registers and signals
    reg [7:0] sA_stage2, sB_stage2;
    reg       valid_stage2;
    reg       feedbackB_stage2, feedbackA_stage2;

    // Stage 3 registers and signals (final output)
    reg [7:0] sA_stage3, sB_stage3;
    reg       valid_stage3;

    // Pipeline Stage 1: Register initial LFSR states and valid
    always @(posedge clk) begin
        if (rst) begin
            sA_stage1   <= 8'hF3;
            sB_stage1   <= 8'h0D;
            valid_stage1 <= 1'b0;
        end else begin
            sA_stage1   <= sA_stage1;
            sB_stage1   <= sB_stage1;
            valid_stage1 <= 1'b1;
        end
    end

    // Pipeline Stage 2: Perform LFSR updates
    always @(posedge clk) begin
        if (rst) begin
            sA_stage2         <= 8'hF3;
            sB_stage2         <= 8'h0D;
            feedbackA_stage2  <= 1'b0;
            feedbackB_stage2  <= 1'b0;
            valid_stage2      <= 1'b0;
        end else begin
            sA_stage2         <= {sA_stage1[6:0], feedbackB_stage1};
            sB_stage2         <= {sB_stage1[6:0], feedbackA_stage1};
            feedbackA_stage2  <= feedbackA_stage1;
            feedbackB_stage2  <= feedbackB_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Pipeline Stage 3: XOR result for output
    always @(posedge clk) begin
        if (rst) begin
            sA_stage3    <= 8'hF3;
            sB_stage3    <= 8'h0D;
            rnd_out      <= 8'hF3 ^ 8'h0D;
            valid_stage3 <= 1'b0;
            rnd_valid    <= 1'b0;
        end else begin
            sA_stage3    <= sA_stage2;
            sB_stage3    <= sB_stage2;
            rnd_out      <= sA_stage2 ^ sB_stage2;
            valid_stage3 <= valid_stage2;
            rnd_valid    <= valid_stage2;
        end
    end
endmodule