module divider_error_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg error
);

always @(*) begin
    if (divisor == 0) begin
        error = 1;
        quotient = 0;
        remainder = 0;
    end else begin
        error = 0;
        quotient = dividend / divisor;
        remainder = dividend % divisor;
    end
end

endmodule