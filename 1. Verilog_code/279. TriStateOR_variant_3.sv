//SystemVerilog
module TriStateOR(
    input oe,       // 输出使能
    input [7:0] a, b,
    output reg [7:0] y
);
    // 声明中间信号
    reg signed [7:0] a_signed, b_signed;
    reg signed [15:0] mult_result;
    reg [7:0] processed_result;
    
    always @(*) begin
        // 将输入转换为有符号数
        a_signed = a;
        b_signed = b;
        
        // 执行带符号乘法
        mult_result = a_signed * b_signed;
        
        // 处理乘法结果，取高8位或低8位，这里选择低8位
        processed_result = mult_result[7:0];
        
        // 三态输出控制
        if (oe) begin
            y = processed_result;
        end else begin
            y = 8'bzzzzzzzz;
        end
    end
endmodule