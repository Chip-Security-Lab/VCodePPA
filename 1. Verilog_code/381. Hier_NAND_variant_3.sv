//SystemVerilog
// 顶层模块
module Hier_NAND(
    input [1:0] a, b,
    output [3:0] y
);
    wire [1:0] nand_results;
    
    // 实例化位操作子模块
    BitOperations bit_ops (
        .a_bits(a),
        .b_bits(b),
        .nand_results(nand_results)
    );
    
    // 实例化输出格式化子模块
    OutputFormatter out_fmt (
        .nand_bits(nand_results),
        .formatted_output(y)
    );
    
endmodule

// 位操作子模块 - 处理NAND运算
module BitOperations (
    input [1:0] a_bits,
    input [1:0] b_bits,
    output [1:0] nand_results
);
    // 直接使用NAND逻辑运算，避免中间信号
    assign nand_results[0] = ~(a_bits[0] & b_bits[0]);
    assign nand_results[1] = ~(a_bits[1] & b_bits[1]);
    
endmodule

// 输出格式化子模块 - 处理最终输出格式
module OutputFormatter (
    input [1:0] nand_bits,
    output [3:0] formatted_output
);
    // 使用拼接操作符更高效地组合输出
    assign formatted_output = {2'b11, nand_bits};
    
endmodule