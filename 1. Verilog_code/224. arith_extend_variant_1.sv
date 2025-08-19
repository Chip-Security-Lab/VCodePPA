//SystemVerilog
// 顶层模块
module arith_extend (
    input [3:0] operand,
    output [4:0] inc,
    output [4:0] dec
);
    // 实例化增量计算子模块
    increment_unit inc_unit (
        .data_in(operand),
        .data_out(inc)
    );
    
    // 实例化减量计算子模块（已优化为借位减法器）
    decrement_unit dec_unit (
        .data_in(operand),
        .data_out(dec)
    );
endmodule

// 增量操作子模块
module increment_unit #(
    parameter WIDTH_IN = 4,
    parameter WIDTH_OUT = 5
)(
    input [WIDTH_IN-1:0] data_in,
    output [WIDTH_OUT-1:0] data_out
);
    // 增量操作实现
    assign data_out = data_in + 1'b1;
endmodule

// 减量操作子模块（使用借位减法器算法实现）
module decrement_unit #(
    parameter WIDTH_IN = 4,
    parameter WIDTH_OUT = 5
)(
    input [WIDTH_IN-1:0] data_in,
    output [WIDTH_OUT-1:0] data_out
);
    // 内部信号定义
    wire [WIDTH_OUT-1:0] extended_in;
    wire [WIDTH_OUT-1:0] borrow;
    
    // 扩展输入数据到输出宽度
    assign extended_in = {1'b0, data_in};
    
    // 借位计算
    assign borrow[0] = 1'b1; // 初始借位为1（减1操作）
    assign borrow[1] = ~extended_in[0] & borrow[0];
    assign borrow[2] = ~extended_in[1] & borrow[1];
    assign borrow[3] = ~extended_in[2] & borrow[2];
    assign borrow[4] = ~extended_in[3] & borrow[3];
    
    // 使用借位减法算法实现减法
    assign data_out[0] = extended_in[0] ^ borrow[0];
    assign data_out[1] = extended_in[1] ^ borrow[1];
    assign data_out[2] = extended_in[2] ^ borrow[2];
    assign data_out[3] = extended_in[3] ^ borrow[3];
    assign data_out[4] = extended_in[4] ^ borrow[4];
endmodule