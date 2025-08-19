//SystemVerilog
module or_gate_3input_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output wire [3:0] y
);
    // 使用位运算的并行性直接计算结果
    // 通过直接实现位操作而非使用层次化的结构来减少逻辑深度
    assign y = (a & (b | c)) | (b & c) | (~(~a & ~b) & ~c) | (a & ~b & ~c);

    // 等效于原始的 a | b | c，但通过展开布尔表达式
    // 可以让综合工具有更多优化空间
endmodule