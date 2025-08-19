module divider_4bit_with_remainder (
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);
    always @(*) begin
        quotient = a / b;
        remainder = a % b;
    end
endmodule
