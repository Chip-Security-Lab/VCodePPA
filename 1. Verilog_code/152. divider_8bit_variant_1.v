module divider_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);

    reg [7:0] quotient_reg;
    reg [7:0] remainder_reg;
    reg [7:0] dividend;
    reg [7:0] divisor;
    
    always @(*) begin
        dividend = a;
        divisor = b;
        quotient_reg = 8'b0;
        remainder_reg = 8'b0;
        
        // Iteration 0
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
        
        // Iteration 1
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
        
        // Iteration 2
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
        
        // Iteration 3
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
        
        // Iteration 4
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
        
        // Iteration 5
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
        
        // Iteration 6
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
        
        // Iteration 7
        remainder_reg = {remainder_reg[6:0], dividend[7]};
        dividend = dividend << 1;
        if (remainder_reg >= divisor) begin
            remainder_reg = remainder_reg - divisor;
            quotient_reg = {quotient_reg[6:0], 1'b1};
        end else begin
            quotient_reg = {quotient_reg[6:0], 1'b0};
        end
    end
    
    assign quotient = quotient_reg;
    assign remainder = remainder_reg;
    
endmodule