module divider_8bit_non_blocking (
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    always @(*) begin
        quotient = a / b;
        remainder = a % b;
    end
endmodule
