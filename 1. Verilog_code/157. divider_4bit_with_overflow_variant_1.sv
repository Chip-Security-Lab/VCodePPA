//SystemVerilog
module divider_4bit_with_overflow (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder,
    output overflow
);

    wire zero_divisor;
    reg [3:0] div_result;
    reg [3:0] mod_result;
    reg [7:0] dividend;
    reg [3:0] divisor;
    reg [3:0] quotient_temp;
    reg [3:0] remainder_temp;
    integer i;

    assign zero_divisor = ~|b;

    always @(*) begin
        dividend = {4'b0000, a};
        divisor = b;
        quotient_temp = 4'b0000;
        remainder_temp = 4'b0000;

        for(i = 3; i >= 0; i = i - 1) begin
            remainder_temp = {remainder_temp[2:0], dividend[i]};
            
            if(remainder_temp >= divisor) begin
                remainder_temp = remainder_temp - divisor;
                quotient_temp[i] = 1'b1;
            end else begin
                quotient_temp[i] = 1'b0;
            end
        end

        div_result = quotient_temp;
        mod_result = remainder_temp;
    end

    assign quotient = {4{zero_divisor}} & 4'b0000 | ~{4{zero_divisor}} & div_result;
    assign remainder = {4{zero_divisor}} & 4'b0000 | ~{4{zero_divisor}} & mod_result;
    assign overflow = zero_divisor;

endmodule