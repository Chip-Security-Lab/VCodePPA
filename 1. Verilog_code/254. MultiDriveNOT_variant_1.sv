//SystemVerilog
// 顶层模块
module MultiDriveNOT(
    input [7:0] vector,
    output [7:0] inverse
);
    // 实例化单比特逆转器处理低两位
    SingleBitInverter inv0 (
        .bit_in(vector[0]),
        .bit_out(inverse[0])
    );
    
    LogicalInverter inv1 (
        .bit_in(vector[1]),
        .bit_out(inverse[1])
    );
    
    // 实例化多比特逆转器处理高6位
    MultiBitInverter #(
        .WIDTH(6)
    ) inv_high (
        .bits_in(vector[7:2]),
        .bits_out(inverse[7:2])
    );
endmodule

// 使用位运算符的单比特逆转器
module SingleBitInverter(
    input bit_in,
    output bit_out
);
    // 使用条件求和减法算法实现NOT操作
    // 1-bit_in 实现NOT功能
    wire [1:0] subtraction_result;
    wire carry;
    
    // 半加器实现1-bit_in
    assign subtraction_result[0] = 1'b1 ^ bit_in;
    assign carry = ~1'b1 & bit_in;
    assign subtraction_result[1] = carry;
    
    assign bit_out = subtraction_result[0];
endmodule

// 使用逻辑非运算符的单比特逆转器
module LogicalInverter(
    input bit_in,
    output bit_out
);
    // 使用条件求和减法算法实现NOT操作
    wire borrow;
    wire minuend = 1'b1;
    
    // 条件求和减法运算：1-bit_in
    assign {borrow, bit_out} = minuend - bit_in;
endmodule

// 参数化多比特逆转器
module MultiBitInverter #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] bits_in,
    output [WIDTH-1:0] bits_out
);
    // 使用条件求和减法算法实现NOT操作
    wire [WIDTH:0] borrows;
    wire [WIDTH-1:0] minuend;
    
    // 设置minuend为全1
    assign minuend = {WIDTH{1'b1}};
    assign borrows[0] = 1'b0;
    
    // 条件求和减法实现
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : subtract_loop
            wire p, g;
            
            // 传播和生成信号
            assign p = minuend[i] ^ bits_in[i];
            assign g = ~minuend[i] & bits_in[i];
            
            // 计算借位和结果
            assign borrows[i+1] = g | (p & borrows[i]);
            assign bits_out[i] = p ^ borrows[i];
        end
    endgenerate
endmodule