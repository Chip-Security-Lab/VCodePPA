//SystemVerilog
module divider_16bit_pipeline (
    input wire clk,
    input wire rst_n,
    input wire [15:0] dividend,
    input wire [15:0] divisor,
    input wire valid_in,
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    output reg valid_out
);

    reg [15:0] dividend_r1, divisor_r1;
    reg [15:0] quotient_r2, remainder_r2;
    reg valid_r1, valid_r2;
    wire zero_divisor;
    
    assign zero_divisor = (divisor == 16'b0);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            dividend_r1 <= 16'b0;
            divisor_r1 <= 16'b0;
            quotient_r2 <= 16'b0;
            remainder_r2 <= 16'b0;
            quotient <= 16'b0;
            remainder <= 16'b0;
            valid_r1 <= 1'b0;
            valid_r2 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // Stage 1: Input registers
            dividend_r1 <= dividend;
            divisor_r1 <= divisor;
            valid_r1 <= valid_in;
            
            // Stage 2: Division computation
            valid_r2 <= valid_r1; // Move valid_r1 assignment up to reduce path delay
            if (valid_r1) begin
                if (zero_divisor) begin
                    quotient_r2 <= 16'hFFFF;
                    remainder_r2 <= dividend_r1;
                end else begin
                    quotient_r2 <= dividend_r1 / divisor_r1;
                    remainder_r2 <= dividend_r1 % divisor_r1;
                end
            end else begin
                quotient_r2 <= 16'b0; // Ensure quotient is reset
                remainder_r2 <= 16'b0; // Ensure remainder is reset
            end
            
            // Stage 3: Output registers
            quotient <= quotient_r2;
            remainder <= remainder_r2;
            valid_out <= valid_r2;
        end
    end

endmodule