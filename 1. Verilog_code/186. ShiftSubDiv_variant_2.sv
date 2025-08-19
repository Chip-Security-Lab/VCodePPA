//SystemVerilog
module ShiftSubDiv(
    input [7:0] dividend, divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [15:0] rem;
    integer i;

    always @(*) begin
        // 每次求值时初始化
        rem = {8'b0, dividend};
        quotient = 0; // 初始化商

        // 移位减法算法
        for(i = 7; i >= 0; i = i - 1) begin
            rem = rem << 1;
            if(divisor != 0 && rem[15:8] >= divisor) begin
                rem[15:8] = rem[15:8] - divisor;
                quotient[i] = 1'b1;
            end
        end
        
        remainder = rem[15:8];
    end
endmodule