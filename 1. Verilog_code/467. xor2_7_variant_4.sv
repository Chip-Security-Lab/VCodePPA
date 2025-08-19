//SystemVerilog
module xor2_7 #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    // 实现二进制补码减法器 (A - B)
    
    // 补码转换信号
    wire [WIDTH-1:0] B_complement;
    wire [WIDTH:0] result_with_carry;
    wire carry_in = 1'b1; // 加1是补码的一部分
    
    // 对B取反 (一的补码)
    assign B_complement = ~B;
    
    // 执行加法: A + ~B + 1 (二进制补码减法)
    assign result_with_carry = {1'b0, A} + {1'b0, B_complement} + {{WIDTH{1'b0}}, carry_in};
    
    // 结果不包含最高位的进位
    assign Y = result_with_carry[WIDTH-1:0];
endmodule