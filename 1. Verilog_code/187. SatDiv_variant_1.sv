//SystemVerilog
module SatDiv(
    input [7:0] a, b,
    output reg [7:0] q
);
    // 使用查找表算法实现除法
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [7:0] quotient;
    reg [3:0] i;
    reg [8:0] partial_remainder;
    
    always @(*) begin
        // 初始化
        dividend = a;
        divisor = b;
        quotient = 0;
        partial_remainder = 0;
        
        if(b == 0) begin
            q = 8'hFF; // 除数为0时饱和到最大值
        end else if(partial_remainder >= divisor && i == 0) begin
            partial_remainder = {partial_remainder[6:0], dividend[7]};
            partial_remainder = partial_remainder - divisor;
            quotient[7] = 1'b1;
            q = quotient;
        end else if(i == 0) begin
            partial_remainder = {partial_remainder[6:0], dividend[7]};
            quotient[7] = 1'b0;
            q = quotient;
        end else if(partial_remainder >= divisor && i == 1) begin
            partial_remainder = {partial_remainder[6:0], dividend[6]};
            partial_remainder = partial_remainder - divisor;
            quotient[6] = 1'b1;
            q = quotient;
        end else if(i == 1) begin
            partial_remainder = {partial_remainder[6:0], dividend[6]};
            quotient[6] = 1'b0;
            q = quotient;
        end else if(partial_remainder >= divisor && i == 2) begin
            partial_remainder = {partial_remainder[6:0], dividend[5]};
            partial_remainder = partial_remainder - divisor;
            quotient[5] = 1'b1;
            q = quotient;
        end else if(i == 2) begin
            partial_remainder = {partial_remainder[6:0], dividend[5]};
            quotient[5] = 1'b0;
            q = quotient;
        end else if(partial_remainder >= divisor && i == 3) begin
            partial_remainder = {partial_remainder[6:0], dividend[4]};
            partial_remainder = partial_remainder - divisor;
            quotient[4] = 1'b1;
            q = quotient;
        end else if(i == 3) begin
            partial_remainder = {partial_remainder[6:0], dividend[4]};
            quotient[4] = 1'b0;
            q = quotient;
        end else if(partial_remainder >= divisor && i == 4) begin
            partial_remainder = {partial_remainder[6:0], dividend[3]};
            partial_remainder = partial_remainder - divisor;
            quotient[3] = 1'b1;
            q = quotient;
        end else if(i == 4) begin
            partial_remainder = {partial_remainder[6:0], dividend[3]};
            quotient[3] = 1'b0;
            q = quotient;
        end else if(partial_remainder >= divisor && i == 5) begin
            partial_remainder = {partial_remainder[6:0], dividend[2]};
            partial_remainder = partial_remainder - divisor;
            quotient[2] = 1'b1;
            q = quotient;
        end else if(i == 5) begin
            partial_remainder = {partial_remainder[6:0], dividend[2]};
            quotient[2] = 1'b0;
            q = quotient;
        end else if(partial_remainder >= divisor && i == 6) begin
            partial_remainder = {partial_remainder[6:0], dividend[1]};
            partial_remainder = partial_remainder - divisor;
            quotient[1] = 1'b1;
            q = quotient;
        end else if(i == 6) begin
            partial_remainder = {partial_remainder[6:0], dividend[1]};
            quotient[1] = 1'b0;
            q = quotient;
        end else if(partial_remainder >= divisor && i == 7) begin
            partial_remainder = {partial_remainder[6:0], dividend[0]};
            partial_remainder = partial_remainder - divisor;
            quotient[0] = 1'b1;
            q = quotient;
        end else begin
            partial_remainder = {partial_remainder[6:0], dividend[0]};
            quotient[0] = 1'b0;
            q = quotient;
        end
    end
endmodule