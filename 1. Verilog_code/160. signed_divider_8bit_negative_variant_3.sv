//SystemVerilog
module signed_divider_8bit_negative (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient,
    output signed [7:0] remainder
);

    wire [7:0] abs_a;
    wire [7:0] abs_b;
    wire [7:0] abs_quotient;
    wire [7:0] abs_remainder;
    wire sign_a;
    wire sign_b;
    wire result_sign;

    abs_sign_calc abs_sign_inst (
        .a(a),
        .b(b),
        .abs_a(abs_a),
        .abs_b(abs_b),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .result_sign(result_sign)
    );

    binary_divider div_core_inst (
        .dividend(abs_a),
        .divisor(abs_b),
        .quotient(abs_quotient),
        .remainder(abs_remainder)
    );

    result_adjust result_adjust_inst (
        .abs_quotient(abs_quotient),
        .abs_remainder(abs_remainder),
        .result_sign(result_sign),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module abs_sign_calc (
    input signed [7:0] a,
    input signed [7:0] b,
    output reg [7:0] abs_a,
    output reg [7:0] abs_b,
    output reg sign_a,
    output reg sign_b,
    output reg result_sign
);

    always @(*) begin
        sign_a = a[7];
        sign_b = b[7];
        abs_a = sign_a ? -a : a;
        abs_b = sign_b ? -b : b;
        result_sign = sign_a ^ sign_b;
    end

endmodule

module binary_divider (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [7:0] temp_dividend;
    reg [7:0] temp_divisor;
    reg [7:0] temp_quotient;
    reg [7:0] temp_remainder;
    integer i;

    always @(*) begin
        temp_dividend = dividend;
        temp_divisor = divisor;
        temp_quotient = 8'b0;
        temp_remainder = 8'b0;

        for (i = 7; i >= 0; i = i - 1) begin
            temp_remainder = {temp_remainder[6:0], temp_dividend[i]};
            
            if (temp_remainder >= temp_divisor) begin
                temp_remainder = temp_remainder - temp_divisor;
                temp_quotient[i] = 1'b1;
            end
        end

        quotient = temp_quotient;
        remainder = temp_remainder;
    end

endmodule

module result_adjust (
    input [7:0] abs_quotient,
    input [7:0] abs_remainder,
    input result_sign,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);

    always @(*) begin
        quotient = result_sign ? -abs_quotient : abs_quotient;
        remainder = result_sign ? -abs_remainder : abs_remainder;
    end

endmodule