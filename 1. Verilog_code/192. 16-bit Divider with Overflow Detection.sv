module divider_16bit (
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    output reg overflow
);

always @(*) begin
    if (divisor == 0) begin
        overflow = 1;
        quotient = 0;
        remainder = 0;
    end else begin
        quotient = dividend / divisor;
        remainder = dividend % divisor;
        overflow = 0;
    end
end

endmodule