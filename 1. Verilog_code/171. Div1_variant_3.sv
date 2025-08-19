//SystemVerilog
module Div1(
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient
);

    reg [7:0] partial_remainder;
    reg [7:0] partial_divisor;
    reg [7:0] quotient_reg;
    reg [3:0] iteration;
    reg [7:0] next_remainder;
    reg [7:0] next_divisor;
    reg [7:0] next_quotient;
    reg [1:0] q_digit;
    reg [1:0] comp_result;

    always @(*) begin
        if (divisor == 8'd0) begin
            quotient_reg = 8'hFF;
        end else begin
            partial_remainder = dividend;
            partial_divisor = divisor;
            quotient_reg = 8'd0;
            
            for (iteration = 0; iteration < 8; iteration = iteration + 1) begin
                next_remainder = {partial_remainder[6:0], 1'b0};
                next_divisor = partial_divisor;
                
                comp_result = {next_remainder >= next_divisor, 
                             next_remainder >= (next_divisor >> 1)};
                
                case (comp_result)
                    2'b11: begin
                        q_digit = 2'b01;
                        next_remainder = next_remainder - next_divisor;
                    end
                    2'b10: begin
                        q_digit = 2'b00;
                    end
                    default: begin
                        q_digit = 2'b11;
                        next_remainder = next_remainder + next_divisor;
                    end
                endcase
                
                quotient_reg = {quotient_reg[6:0], q_digit[0]};
                partial_remainder = next_remainder;
            end
        end
    end

    assign quotient = quotient_reg;

endmodule