//SystemVerilog
module ITRC_SequenceDetect #(
    parameter SEQ_PATTERN = 3'b101
)(
    input clk,
    input rst_n,
    input int_in,
    output reg seq_detected
);

    reg [1:0] shift_reg_stage1;
    reg valid_stage1;
    reg [1:0] shift_reg_stage2;
    reg valid_stage2;
    reg [1:0] shift_reg_stage3;
    reg valid_stage3;
    reg [2:0] pattern_match;
    reg valid_stage4;

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 2'b0;
            valid_stage1 <= 1'b0;
            shift_reg_stage2 <= 2'b0;
            valid_stage2 <= 1'b0;
            shift_reg_stage3 <= 2'b0;
            valid_stage3 <= 1'b0;
            pattern_match <= 3'b0;
            valid_stage4 <= 1'b0;
            seq_detected <= 1'b0;
        end else begin
            // Stage 1: Input sampling
            shift_reg_stage1 <= {shift_reg_stage1[0], int_in};
            valid_stage1 <= 1'b1;

            // Stage 2: First shift
            shift_reg_stage2 <= shift_reg_stage1;
            valid_stage2 <= valid_stage1;

            // Stage 3: Second shift
            shift_reg_stage3 <= shift_reg_stage2;
            valid_stage3 <= valid_stage2;

            // Stage 4: Pattern matching
            pattern_match <= {shift_reg_stage3, shift_reg_stage2[0]};
            valid_stage4 <= valid_stage3;

            // Stage 5: Output generation
            seq_detected <= valid_stage4 && (pattern_match == SEQ_PATTERN);
        end
    end

endmodule