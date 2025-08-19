module divider_signed_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

always @(*) begin
    quotient = dividend / divisor;
    remainder = dividend % divisor;
end

endmodule