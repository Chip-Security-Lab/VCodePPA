//SystemVerilog
module divider_error_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient,
    output [7:0] remainder,
    output error
);

// Error detection module
divider_error_detector #(
    .WIDTH(8)
) error_detector (
    .divisor(divisor),
    .error(error)
);

// Division operation module
divider_core #(
    .WIDTH(8)
) divider (
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient),
    .remainder(remainder)
);

endmodule

module divider_error_detector #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] divisor,
    output reg error
);

always @(*) begin
    error = (divisor == {WIDTH{1'b0}});
end

endmodule

module divider_core #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output reg [WIDTH-1:0] quotient,
    output reg [WIDTH-1:0] remainder
);

always @(*) begin
    if (divisor == {WIDTH{1'b0}}) begin
        quotient = {WIDTH{1'b0}};
        remainder = {WIDTH{1'b0}};
    end else begin
        quotient = dividend / divisor;
        remainder = dividend % divisor;
    end
end

endmodule