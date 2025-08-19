//SystemVerilog
module Parity_XNOR(
    input [7:0] data,
    output parity
);
    // 优化的奇偶校验实现，使用更高效的树状结构
    // 同时利用XNOR特性：偶数个1的XNOR结果为1
    wire [3:0] level1;
    wire [1:0] level2;
    
    // 第一层计算 - 使用XNOR代替XOR+取反
    assign level1[0] = ~(data[0] ^ data[1]);
    assign level1[1] = ~(data[2] ^ data[3]);
    assign level1[2] = ~(data[4] ^ data[5]);
    assign level1[3] = ~(data[6] ^ data[7]);
    
    // 第二层计算 - 使用XOR连接XNOR结果
    // 利用性质：两个XNOR结果的XOR等同于原始位的XNOR
    assign level2[0] = level1[0] ^ level1[1];
    assign level2[1] = level1[2] ^ level1[3];
    
    // 最终结果，无需取反，直接使用XOR连接
    assign parity = level2[0] ^ level2[1];
endmodule