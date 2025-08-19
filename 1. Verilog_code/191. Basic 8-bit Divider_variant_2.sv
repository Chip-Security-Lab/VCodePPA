//SystemVerilog
module divider_8bit (
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
            temp_remainder = temp_remainder + (~temp_divisor + 1'b1); // 使用补码实现减法
            temp_quotient[i] = 1'b1;
        end else begin
            temp_quotient[i] = 1'b0;
        end
    end

    quotient = temp_quotient;
    remainder = temp_remainder;
end

endmodule