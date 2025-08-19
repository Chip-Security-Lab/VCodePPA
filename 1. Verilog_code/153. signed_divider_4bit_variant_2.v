module signed_divider_4bit (
    input wire clk,
    input wire rst_n,
    input signed [3:0] dividend,
    input signed [3:0] divisor,
    output reg signed [3:0] quotient,
    output reg signed [3:0] remainder
);

    // Pipeline stage 1: Input registers and sign detection
    reg signed [3:0] dividend_reg1;
    reg signed [3:0] divisor_reg1;
    reg dividend_sign_reg1;
    reg divisor_sign_reg1;
    
    // Pipeline stage 2: Absolute value calculation
    reg signed [3:0] abs_dividend_reg2;
    reg signed [3:0] abs_divisor_reg2;
    reg quotient_sign_reg2;
    reg remainder_sign_reg2;
    
    // Pipeline stage 3: Division computation
    reg signed [3:0] abs_quotient_reg3;
    reg signed [3:0] abs_remainder_reg3;
    reg quotient_sign_reg3;
    reg remainder_sign_reg3;

    // Stage 1: Input registration and sign detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg1 <= 4'b0;
            divisor_reg1 <= 4'b0;
            dividend_sign_reg1 <= 1'b0;
            divisor_sign_reg1 <= 1'b0;
        end else begin
            dividend_reg1 <= dividend;
            divisor_reg1 <= divisor;
            dividend_sign_reg1 <= dividend[3];
            divisor_sign_reg1 <= divisor[3];
        end
    end

    // Stage 2: Absolute value calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_dividend_reg2 <= 4'b0;
            abs_divisor_reg2 <= 4'b0;
            quotient_sign_reg2 <= 1'b0;
            remainder_sign_reg2 <= 1'b0;
        end else begin
            abs_dividend_reg2 <= (dividend_sign_reg1) ? -dividend_reg1 : dividend_reg1;
            abs_divisor_reg2 <= (divisor_sign_reg1) ? -divisor_reg1 : divisor_reg1;
            quotient_sign_reg2 <= dividend_sign_reg1 ^ divisor_sign_reg1;
            remainder_sign_reg2 <= dividend_sign_reg1;
        end
    end

    // Stage 3: Division computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_quotient_reg3 <= 4'b0;
            abs_remainder_reg3 <= 4'b0;
            quotient_sign_reg3 <= 1'b0;
            remainder_sign_reg3 <= 1'b0;
        end else begin
            abs_quotient_reg3 <= abs_dividend_reg2 / abs_divisor_reg2;
            abs_remainder_reg3 <= abs_dividend_reg2 % abs_divisor_reg2;
            quotient_sign_reg3 <= quotient_sign_reg2;
            remainder_sign_reg3 <= remainder_sign_reg2;
        end
    end

    // Stage 4: Final sign application and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 4'b0;
            remainder <= 4'b0;
        end else begin
            quotient <= (quotient_sign_reg3) ? -abs_quotient_reg3 : abs_quotient_reg3;
            remainder <= (remainder_sign_reg3) ? -abs_remainder_reg3 : abs_remainder_reg3;
        end
    end

endmodule