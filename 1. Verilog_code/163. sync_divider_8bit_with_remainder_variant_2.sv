//SystemVerilog
module sync_divider_8bit_with_remainder (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Pipeline stage 1: Input register and initial division
    reg [7:0] a_stage1, b_stage1;
    reg [7:0] partial_quotient_stage1;
    reg [7:0] partial_remainder_stage1;
    reg valid_stage1;

    // Pipeline stage 2: Division refinement
    reg [7:0] a_stage2, b_stage2;
    reg [7:0] partial_quotient_stage2;
    reg [7:0] partial_remainder_stage2;
    reg valid_stage2;

    // Pipeline stage 3: Final calculation
    reg [7:0] a_stage3, b_stage3;
    reg [7:0] final_quotient_stage3;
    reg [7:0] final_remainder_stage3;
    reg valid_stage3;

    // Pipeline stage 4: Output register
    reg [7:0] final_quotient_stage4;
    reg [7:0] final_remainder_stage4;
    reg valid_stage4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all pipeline stages
            a_stage1 <= 0; b_stage1 <= 0;
            partial_quotient_stage1 <= 0;
            partial_remainder_stage1 <= 0;
            valid_stage1 <= 0;

            a_stage2 <= 0; b_stage2 <= 0;
            partial_quotient_stage2 <= 0;
            partial_remainder_stage2 <= 0;
            valid_stage2 <= 0;

            a_stage3 <= 0; b_stage3 <= 0;
            final_quotient_stage3 <= 0;
            final_remainder_stage3 <= 0;
            valid_stage3 <= 0;

            final_quotient_stage4 <= 0;
            final_remainder_stage4 <= 0;
            valid_stage4 <= 0;

            quotient <= 0;
            remainder <= 0;
        end else begin
            // Stage 1: Input registration and initial division
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1;
            if (b_stage1[7:4] != 0) begin
                partial_quotient_stage1 <= a_stage1[7:4] / b_stage1[7:4];
                partial_remainder_stage1 <= a_stage1[7:4] % b_stage1[7:4];
            end else begin
                partial_quotient_stage1 <= 0;
                partial_remainder_stage1 <= a_stage1[7:4];
            end

            // Stage 2: Division refinement
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            valid_stage2 <= valid_stage1;
            if (valid_stage1 && b_stage2 != 0) begin
                partial_quotient_stage2 <= (partial_remainder_stage1 << 4 | a_stage2[3:0]) / b_stage2;
                partial_remainder_stage2 <= (partial_remainder_stage1 << 4 | a_stage2[3:0]) % b_stage2;
            end else begin
                partial_quotient_stage2 <= 0;
                partial_remainder_stage2 <= (partial_remainder_stage1 << 4 | a_stage2[3:0]);
            end

            // Stage 3: Final calculation
            a_stage3 <= a_stage2;
            b_stage3 <= b_stage2;
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                final_quotient_stage3 <= (partial_quotient_stage1 << 4) | partial_quotient_stage2;
                final_remainder_stage3 <= partial_remainder_stage2;
            end else begin
                final_quotient_stage3 <= 0;
                final_remainder_stage3 <= 0;
            end

            // Stage 4: Output register
            valid_stage4 <= valid_stage3;
            if (valid_stage3) begin
                final_quotient_stage4 <= final_quotient_stage3;
                final_remainder_stage4 <= final_remainder_stage3;
            end else begin
                final_quotient_stage4 <= 0;
                final_remainder_stage4 <= 0;
            end

            // Output stage
            quotient <= final_quotient_stage4;
            remainder <= final_remainder_stage4;
        end
    end
endmodule