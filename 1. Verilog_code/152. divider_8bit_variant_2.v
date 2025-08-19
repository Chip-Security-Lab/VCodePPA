module divider_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);

    divider_core u_divider_core (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module divider_core (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [7:0] temp_dividend;
    reg [7:0] temp_divisor;
    reg [7:0] temp_quotient;
    reg [7:0] temp_remainder;
    reg [7:0] next_remainder;
    reg [7:0] next_quotient;
    integer i;

    // 初始化逻辑
    always @(*) begin
        temp_dividend = dividend;
        temp_divisor = divisor;
        temp_quotient = 8'b0;
        temp_remainder = 8'b0;
    end

    // 迭代计算逻辑
    always @(*) begin
        next_remainder = temp_remainder;
        next_quotient = temp_quotient;
        
        for (i = 7; i >= 0; i = i - 1) begin
            next_remainder = {next_remainder[6:0], temp_dividend[i]};
            
            if (next_remainder >= temp_divisor) begin
                next_remainder = next_remainder - temp_divisor;
                next_quotient[i] = 1'b1;
            end
        end
    end

    // 输出更新逻辑
    always @(*) begin
        quotient = next_quotient;
        remainder = next_remainder;
    end

endmodule