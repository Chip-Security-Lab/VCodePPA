//SystemVerilog
module divider_16bit_unsigned (
    input [15:0] a,
    input [15:0] b,
    output [15:0] quotient,
    output [15:0] remainder
);

    divider_core u_divider_core (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module divider_core (
    input [15:0] dividend,
    input [15:0] divisor,
    output [15:0] quotient,
    output [15:0] remainder
);

    reg [15:0] quotient_reg;
    reg [15:0] remainder_reg;
    reg [15:0] temp_dividend;
    reg [15:0] temp_divisor;
    reg [4:0] iteration_count;

    always @(*) begin
        temp_dividend = dividend;
        temp_divisor = divisor;
        quotient_reg = 16'b0;
        remainder_reg = 16'b0;
        
        for (iteration_count = 0; iteration_count < 16; iteration_count = iteration_count + 1) begin
            remainder_reg = {remainder_reg[14:0], temp_dividend[15]};
            temp_dividend = {temp_dividend[14:0], 1'b0};
            
            if (remainder_reg >= temp_divisor) begin
                remainder_reg = remainder_reg - temp_divisor;
                quotient_reg = {quotient_reg[14:0], 1'b1};
            end else begin
                quotient_reg = {quotient_reg[14:0], 1'b0};
            end
        end
    end

    assign quotient = quotient_reg;
    assign remainder = remainder_reg;

endmodule