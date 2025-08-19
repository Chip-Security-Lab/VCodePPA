//SystemVerilog
module divider_with_counter (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Pipeline stage registers
    reg [7:0] a_stage1;
    reg [7:0] b_stage1;
    reg valid_stage1;
    reg [7:0] quotient_stage2;
    reg [7:0] remainder_stage2;
    reg valid_stage2;
    reg [7:0] quotient_stage3;
    reg [7:0] remainder_stage3;
    reg valid_stage3;
    reg [3:0] cycle_count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all pipeline stages
            a_stage1 <= 0;
            b_stage1 <= 0;
            valid_stage1 <= 0;
            quotient_stage2 <= 0;
            remainder_stage2 <= 0;
            valid_stage2 <= 0;
            quotient_stage3 <= 0;
            remainder_stage3 <= 0;
            valid_stage3 <= 0;
            cycle_count <= 0;
            quotient <= 0;
            remainder <= 0;
        end else begin
            // Stage 1: Input registration
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1;

            // Stage 2: Division calculation
            if (valid_stage1) begin
                quotient_stage2 <= a_stage1 / b_stage1;
                remainder_stage2 <= a_stage1 % b_stage1;
                valid_stage2 <= 1;
            end else begin
                valid_stage2 <= 0;
            end

            // Stage 3: Output registration
            if (valid_stage2) begin
                quotient_stage3 <= quotient_stage2;
                remainder_stage3 <= remainder_stage2;
                valid_stage3 <= 1;
                cycle_count <= cycle_count + 1;
            end else begin
                valid_stage3 <= 0;
            end

            // Output assignment
            if (valid_stage3 && cycle_count < 8) begin
                quotient <= quotient_stage3;
                remainder <= remainder_stage3;
            end
        end
    end

endmodule