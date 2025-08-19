//SystemVerilog
module code_converter (
    input [2:0] binary,
    output [2:0] gray,
    output [7:0] one_hot
);

    // 优化的Gray码转换
    // 直接使用位操作，无需中间变量
    assign gray = {binary[2], binary[2:1] ^ binary[1:0]};

    // 优化的独热码转换
    // 使用移位运算直接生成独热码，避免复杂的条件表达式
    assign one_hot = 8'b00000001 << binary;

endmodule