module signed_divider_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    reg signed [3:0] quotient_reg;
    reg signed [3:0] remainder_reg;
    reg signed [7:0] dividend;
    reg signed [3:0] divisor;
    reg [2:0] iteration;
    reg sign;

    always @(*) begin
        sign = a[3] ^ b[3];
        dividend = {4'b0, (a[3] ? -a : a)};
        divisor = (b[3] ? -b : b);
        quotient_reg = 4'b0;
        remainder_reg = 4'b0;

        for (iteration = 0; iteration < 4; iteration = iteration + 1) begin
            quotient_reg = {quotient_reg[2:0], (dividend[7:4] >= divisor)};
            dividend = dividend[7:4] >= divisor ? 
                      {dividend[6:0], 1'b0} - {divisor, 4'b0} : 
                      {dividend[6:0], 1'b0};
        end

        remainder_reg = dividend[7:4];
        if (sign) begin
            quotient_reg = -quotient_reg;
            remainder_reg = -remainder_reg;
        end
    end

    assign quotient = quotient_reg;
    assign remainder = remainder_reg;

endmodule