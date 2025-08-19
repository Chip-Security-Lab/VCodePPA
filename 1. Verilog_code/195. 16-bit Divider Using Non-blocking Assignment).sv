module divider_16bit_nba (
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

always @(*) begin
    quotient <= dividend / divisor;
    remainder <= dividend % divisor;
end

endmodule