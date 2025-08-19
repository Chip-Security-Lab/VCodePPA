//SystemVerilog
module BiDir_NAND(
    inout [7:0] bus_a, bus_b,
    input dir,
    output [7:0] result
);
    wire [7:0] nand_result;
    
    // 计算NAND结果
    assign nand_result = ~(bus_a & bus_b);
    
    // 使用显式多路复用器结构替代三元运算符
    assign bus_a = dir ? nand_result : 8'hzz;
    assign bus_b = dir ? 8'hzz : nand_result;
    
    // 输出结果
    assign result = nand_result;
endmodule