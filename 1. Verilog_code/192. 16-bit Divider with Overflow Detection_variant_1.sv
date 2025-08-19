//SystemVerilog
module divider_16bit (
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    output reg overflow
);

wire divisor_is_zero;
assign divisor_is_zero = ~|divisor;  // Efficient way to check if all bits are zero

always @(*) begin
    overflow = divisor_is_zero;
    
    if (divisor_is_zero) begin
        quotient = 16'b0;
        remainder = 16'b0;
    end else begin
        quotient = dividend / divisor;
        remainder = dividend % divisor;
    end
end

endmodule