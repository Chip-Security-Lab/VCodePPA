//SystemVerilog
module divider_sync_reset (
    input clk,
    input reset,
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

    // Pipeline registers
    reg [15:0] dividend_stage1, divisor_stage1;
    reg [15:0] dividend_stage2, divisor_stage2;
    reg [15:0] dividend_stage3, divisor_stage3;
    reg [15:0] dividend_stage4, divisor_stage4;
    
    // Intermediate results
    reg [15:0] partial_quotient_stage1;
    reg [15:0] partial_remainder_stage1;
    reg [15:0] partial_quotient_stage2;
    reg [15:0] partial_remainder_stage2;
    reg [15:0] partial_quotient_stage3;
    reg [15:0] partial_remainder_stage3;
    
    // Control signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Stage 1: Input registration
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dividend_stage1 <= 0;
            divisor_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            dividend_stage1 <= dividend;
            divisor_stage1 <= divisor;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: First division step
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dividend_stage2 <= 0;
            divisor_stage2 <= 0;
            partial_quotient_stage1 <= 0;
            partial_remainder_stage1 <= 0;
            valid_stage2 <= 0;
        end else begin
            dividend_stage2 <= dividend_stage1;
            divisor_stage2 <= divisor_stage1;
            partial_quotient_stage1 <= dividend_stage1[15:8] / divisor_stage1[15:8];
            partial_remainder_stage1 <= dividend_stage1[15:8] % divisor_stage1[15:8];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Second division step
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dividend_stage3 <= 0;
            divisor_stage3 <= 0;
            partial_quotient_stage2 <= 0;
            partial_remainder_stage2 <= 0;
            valid_stage3 <= 0;
        end else begin
            dividend_stage3 <= dividend_stage2;
            divisor_stage3 <= divisor_stage2;
            partial_quotient_stage2 <= (partial_remainder_stage1 << 8 | dividend_stage2[7:0]) / divisor_stage2[15:8];
            partial_remainder_stage2 <= (partial_remainder_stage1 << 8 | dividend_stage2[7:0]) % divisor_stage2[15:8];
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Final result computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            valid_stage4 <= 0;
        end else begin
            quotient <= (partial_quotient_stage1 << 8) | partial_quotient_stage2;
            remainder <= partial_remainder_stage2;
            valid_stage4 <= valid_stage3;
        end
    end

endmodule