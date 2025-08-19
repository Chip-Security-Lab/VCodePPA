//SystemVerilog
module multi_cycle_divider (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    input valid_in,
    output reg ready_in,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg valid_out,
    input ready_out
);

    // Pipeline stage 1: Input register
    reg [7:0] dividend_stage1;
    reg [7:0] divisor_stage1;
    reg [3:0] count_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Division preparation
    reg [7:0] dividend_stage2;
    reg [7:0] divisor_stage2;
    reg [3:0] count_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Division calculation
    reg [7:0] dividend_stage3;
    reg [7:0] divisor_stage3;
    reg [3:0] count_stage3;
    reg [7:0] quotient_stage3;
    reg [7:0] remainder_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4: Output register
    reg [7:0] quotient_stage4;
    reg [7:0] remainder_stage4;
    reg valid_stage4;

    // Backpressure logic
    wire stage1_ready = !valid_stage1 || (valid_stage2 && ready_stage2);
    wire stage2_ready = !valid_stage2 || (valid_stage3 && ready_stage3);
    wire stage3_ready = !valid_stage3 || (valid_stage4 && ready_stage4);
    wire stage4_ready = !valid_stage4 || (valid_out && ready_out);
    
    wire ready_stage2 = stage2_ready;
    wire ready_stage3 = stage3_ready;
    wire ready_stage4 = stage4_ready;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Stage 1 reset
            dividend_stage1 <= 0;
            divisor_stage1 <= 0;
            count_stage1 <= 0;
            valid_stage1 <= 0;
            
            // Stage 2 reset
            dividend_stage2 <= 0;
            divisor_stage2 <= 0;
            count_stage2 <= 0;
            valid_stage2 <= 0;
            
            // Stage 3 reset
            dividend_stage3 <= 0;
            divisor_stage3 <= 0;
            count_stage3 <= 0;
            quotient_stage3 <= 0;
            remainder_stage3 <= 0;
            valid_stage3 <= 0;
            
            // Stage 4 reset
            quotient_stage4 <= 0;
            remainder_stage4 <= 0;
            valid_stage4 <= 0;
            
            // Output reset
            quotient <= 0;
            remainder <= 0;
            valid_out <= 0;
            ready_in <= 1;
        end else begin
            // Stage 1: Input register
            if (valid_in && ready_in) begin
                dividend_stage1 <= a;
                divisor_stage1 <= b;
                count_stage1 <= 0;
                valid_stage1 <= 1;
            end else if (valid_stage1 && ready_stage2) begin
                valid_stage1 <= 0;
            end
            
            // Stage 2: Division preparation
            if (valid_stage1 && ready_stage2) begin
                dividend_stage2 <= dividend_stage1;
                divisor_stage2 <= divisor_stage1;
                count_stage2 <= count_stage1;
                valid_stage2 <= 1;
            end else if (valid_stage2 && ready_stage3) begin
                valid_stage2 <= 0;
            end
            
            // Stage 3: Division calculation
            if (valid_stage2 && ready_stage3) begin
                dividend_stage3 <= dividend_stage2;
                divisor_stage3 <= divisor_stage2;
                count_stage3 <= count_stage2;
                quotient_stage3 <= dividend_stage2 / divisor_stage2;
                remainder_stage3 <= dividend_stage2 % divisor_stage2;
                valid_stage3 <= 1;
            end else if (valid_stage3 && ready_stage4) begin
                valid_stage3 <= 0;
            end
            
            // Stage 4: Output register
            if (valid_stage3 && ready_stage4) begin
                quotient_stage4 <= quotient_stage3;
                remainder_stage4 <= remainder_stage3;
                valid_stage4 <= 1;
            end else if (valid_stage4 && ready_out) begin
                valid_stage4 <= 0;
            end
            
            // Final output
            if (valid_stage4 && ready_out) begin
                quotient <= quotient_stage4;
                remainder <= remainder_stage4;
                valid_out <= 1;
            end else if (!ready_out) begin
                valid_out <= 0;
            end
            
            // Input ready logic
            ready_in <= !valid_stage1 || (valid_stage2 && ready_stage2);
        end
    end
endmodule