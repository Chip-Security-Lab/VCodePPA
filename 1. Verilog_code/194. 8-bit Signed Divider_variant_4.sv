//SystemVerilog
module divider_signed_8bit (
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient,
    output [7:0] remainder
);
    wire [7:0] abs_dividend = dividend[7] ? ~dividend + 1'b1 : dividend;
    wire [7:0] abs_divisor = divisor[7] ? ~divisor + 1'b1 : divisor;
    wire result_sign = dividend[7] ^ divisor[7];
    
    wire [7:0] abs_quotient, abs_remainder;
    
    assign {abs_quotient, abs_remainder} = abs_divisor != 0 ? 
        {abs_dividend / abs_divisor, abs_dividend % abs_divisor} : 
        {8'hFF, abs_dividend};
    
    assign quotient = result_sign ? ~abs_quotient + 1'b1 : abs_quotient;
    assign remainder = dividend[7] ? ~abs_remainder + 1'b1 : abs_remainder;
endmodule