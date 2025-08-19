module divider_4bit (
    input [3:0] a,  // 被除数
    input [3:0] b,  // 除数
    output [3:0] quotient,  // 商
    output [3:0] remainder  // 余数
);
    assign quotient = a / b;  // 除法运算
    assign remainder = a % b;  // 余数运算
endmodule
