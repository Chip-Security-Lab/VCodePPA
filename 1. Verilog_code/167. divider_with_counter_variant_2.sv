//SystemVerilog
module divider_with_counter_pipelined (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Pipeline registers
    reg [7:0] dividend_stage1;
    reg [7:0] divisor_stage1;
    reg [7:0] quotient_stage1;
    reg [7:0] remainder_stage1;
    reg valid_stage1;
    
    reg [7:0] quotient_stage2;
    reg [7:0] remainder_stage2;
    reg valid_stage2;
    
    reg [7:0] quotient_stage3;
    reg [7:0] remainder_stage3;
    reg valid_stage3;
    
    reg [3:0] cycle_count;
    
    // Stage 1: Input registration and initial calculation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dividend_stage1 <= 0;
            divisor_stage1 <= 0;
            quotient_stage1 <= 0;
            remainder_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            dividend_stage1 <= a;
            divisor_stage1 <= b;
            quotient_stage1 <= a / b;
            remainder_stage1 <= a % b;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: Intermediate calculation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient_stage2 <= 0;
            remainder_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            quotient_stage2 <= quotient_stage1;
            remainder_stage2 <= remainder_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Final calculation and output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient_stage3 <= 0;
            remainder_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            quotient_stage3 <= quotient_stage2;
            remainder_stage3 <= remainder_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            cycle_count <= 0;
        end else if (valid_stage3 && cycle_count < 8) begin
            quotient <= quotient_stage3;
            remainder <= remainder_stage3;
            cycle_count <= cycle_count + 1;
        end
    end

endmodule