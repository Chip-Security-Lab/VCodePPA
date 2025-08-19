//SystemVerilog
module divider_error_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg error
);

always @(*) begin
    // Initialize outputs
    {quotient, remainder, error} = (divisor == 8'b0) ? {8'b0, 8'b0, 1'b1} : {dividend / divisor, dividend % divisor, 1'b0};
end

endmodule