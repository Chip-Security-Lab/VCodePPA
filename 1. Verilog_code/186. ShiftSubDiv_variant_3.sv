//SystemVerilog
module ShiftSubDiv(
    input [7:0] dividend, divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [15:0] rem;
    reg [7:0] div_check;
    reg divisor_nonzero;
    integer i;
    
    always @(*) begin
        // 预先检查除数是否为0
        divisor_nonzero = |divisor;
        
        // 每次求值时初始化
        rem = {8'b0, dividend};
        quotient = 0;
        
        // 移位减法算法 - 优化版本
        for(i=0; i<8; i=i+1) begin
            rem = rem << 1;
            div_check = rem[15:8];
            
            // 使用减法而不是比较，直接计算下一状态
            if(divisor_nonzero) begin
                if(div_check >= divisor) begin
                    rem[15:8] = div_check - divisor;
                    quotient[7-i] = 1'b1;
                end
            end
        end
        
        remainder = rem[15:8];
    end
endmodule