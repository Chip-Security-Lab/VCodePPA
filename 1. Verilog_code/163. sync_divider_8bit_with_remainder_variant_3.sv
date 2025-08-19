//SystemVerilog
module sync_divider_8bit_with_remainder (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Pipeline stage 1 registers
    reg [7:0] a_stage1;
    reg [7:0] b_stage1;
    reg valid_stage1;

    // Pipeline stage 2 registers
    reg [7:0] a_stage2;
    reg [7:0] b_stage2;
    reg valid_stage2;

    // Pipeline stage 3 registers
    reg [7:0] a_stage3;
    reg [7:0] b_stage3;
    reg valid_stage3;

    // Stage 1: Input registration
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_stage1 <= 0;
            b_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1;
        end
    end

    // Stage 2: First pipeline stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_stage2 <= 0;
            b_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Final computation and output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            valid_stage3 <= 0;
        end else begin
            if (valid_stage2) begin
                quotient <= a_stage2 / b_stage2;
                remainder <= a_stage2 % b_stage2;
            end
            valid_stage3 <= valid_stage2;
        end
    end

endmodule