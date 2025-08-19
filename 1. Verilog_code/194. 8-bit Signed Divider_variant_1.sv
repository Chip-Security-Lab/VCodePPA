//SystemVerilog
module divider_signed_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient,
    output [7:0] remainder
);

wire [7:0] quotient_internal;
wire [7:0] remainder_internal;

divider_core core (
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient_internal),
    .remainder(remainder_internal)
);

assign quotient = quotient_internal;
assign remainder = remainder_internal;

endmodule

module divider_core (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

reg [7:0] dividend_reg;
reg [7:0] divisor_reg;
reg [7:0] temp_dividend;
reg [7:0] temp_divisor;
reg [7:0] temp_quotient;
reg [7:0] temp_remainder;
reg dividend_sign;
reg divisor_sign;
reg result_sign;
reg [3:0] count;

always @(*) begin
    dividend_sign = dividend[7];
    divisor_sign = divisor[7];
    result_sign = dividend_sign ^ divisor_sign;
    
    if (dividend_sign) begin
        dividend_reg = -dividend;
    end else begin
        dividend_reg = dividend;
    end
    
    if (divisor_sign) begin
        divisor_reg = -divisor;
    end else begin
        divisor_reg = divisor;
    end
    
    temp_dividend = dividend_reg;
    temp_divisor = divisor_reg;
    temp_quotient = 8'b0;
    temp_remainder = 8'b0;
    
    for (count = 0; count < 8; count = count + 1) begin
        temp_remainder = {temp_remainder[6:0], temp_dividend[7]};
        temp_dividend = {temp_dividend[6:0], 1'b0};
        
        if (temp_remainder >= temp_divisor) begin
            temp_remainder = temp_remainder - temp_divisor;
            temp_quotient = {temp_quotient[6:0], 1'b1};
        end else begin
            temp_quotient = {temp_quotient[6:0], 1'b0};
        end
    end
    
    if (result_sign) begin
        quotient = -temp_quotient;
    end else begin
        quotient = temp_quotient;
    end
    
    if (dividend_sign) begin
        remainder = -temp_remainder;
    end else begin
        remainder = temp_remainder;
    end
end

endmodule