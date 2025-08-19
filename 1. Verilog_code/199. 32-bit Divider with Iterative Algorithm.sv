module divider_iterative_32bit (
    input [31:0] dividend,
    input [31:0] divisor,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

integer i;

always @(*) begin
    quotient = 0;
    remainder = dividend;
    for (i = 0; i < 32; i = i + 1) begin
        if (remainder >= divisor) begin
            remainder = remainder - divisor;
            quotient = quotient + 1;
        end
    end
end

endmodule