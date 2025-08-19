//SystemVerilog
module subtract_shift_right (
    input [7:0] a,
    input [7:0] b,
    input [2:0] shift_amount,
    output [7:0] difference,
    output [7:0] shifted_result
);
    // 先行借位减法器实现
    wire [7:0] p;       // 生成信号 (propagate)
    wire [7:0] g;       // 产生信号 (generate)
    wire [8:0] borrow;  // 借位信号，多一位用于初始借位

    // 计算 p 和 g
    assign p = a ^ b;
    assign g = ~a & b;
    
    // 计算借位信号
    assign borrow[0] = 1'b0;  // 初始无借位
    assign borrow[1] = g[0];
    assign borrow[2] = g[1] | (p[1] & borrow[1]);
    assign borrow[3] = g[2] | (p[2] & borrow[2]);
    assign borrow[4] = g[3] | (p[3] & borrow[3]);
    assign borrow[5] = g[4] | (p[4] & borrow[4]);
    assign borrow[6] = g[5] | (p[5] & borrow[5]);
    assign borrow[7] = g[6] | (p[6] & borrow[6]);
    assign borrow[8] = g[7] | (p[7] & borrow[7]);
    
    // 计算差值
    assign difference = p ^ borrow[7:0];
    
    // 右移运算保持不变
    assign shifted_result = a >> shift_amount;
endmodule