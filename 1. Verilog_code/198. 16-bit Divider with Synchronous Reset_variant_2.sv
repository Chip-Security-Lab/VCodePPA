//SystemVerilog
module divider_sync_reset (
    input clk,
    input reset,
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

// Intermediate signals for pipelining
reg [15:0] dividend_stage1;
reg [15:0] divisor_stage1;
reg [15:0] quotient_stage2;
reg [15:0] remainder_stage2;

// Stage 1: Register inputs
always @(posedge clk or posedge reset) begin
    if (reset) begin
        dividend_stage1 <= 16'b0;
        divisor_stage1 <= 16'b0;
    end else begin
        dividend_stage1 <= dividend;
        divisor_stage1 <= divisor;
    end
end

// Stage 2: Perform division and modulus
always @(posedge clk or posedge reset) begin
    if (reset) begin
        quotient_stage2 <= 16'b0;
        remainder_stage2 <= 16'b0;
    end else begin
        quotient_stage2 <= dividend_stage1 / divisor_stage1;
        remainder_stage2 <= dividend_stage1 % divisor_stage1;
    end
end

// Stage 3: Output results
always @(posedge clk or posedge reset) begin
    if (reset) begin
        quotient <= 16'b0;
        remainder <= 16'b0;
    end else begin
        quotient <= quotient_stage2;
        remainder <= remainder_stage2;
    end
end

endmodule