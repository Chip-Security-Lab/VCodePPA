//SystemVerilog
module Div1(
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient
);

reg [7:0] remainder;
reg [7:0] temp_divisor;
reg [7:0] temp_dividend;
integer i;

always @(*) begin
    if (divisor == 8'b0) begin
        quotient = 8'hFF;
    end else begin
        remainder = 8'b0;
        temp_divisor = divisor;
        temp_dividend = dividend;
        quotient = 8'b0;
        
        for (i = 7; i >= 0; i = i - 1) begin
            remainder = {remainder[6:0], temp_dividend[i]};
            if (remainder >= temp_divisor) begin
                remainder = remainder - temp_divisor;
                quotient[i] = 1'b1;
            end
        end
    end
end

endmodule