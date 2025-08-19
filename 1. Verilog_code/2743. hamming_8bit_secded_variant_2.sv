//SystemVerilog
module hamming_8bit_secded(
    input [7:0] data,
    output [12:0] code
);
    // 优化：直接计算各个奇偶校验位，无需使用位掩码和异或
    wire p0, p1, p2, p3;
    wire overall_parity;
    
    // 计算奇偶校验位，直接使用相关位的异或
    assign p0 = data[0] ^ data[2] ^ data[4] ^ data[6];
    assign p1 = data[1] ^ data[2] ^ data[5] ^ data[6];
    assign p2 = data[3] ^ data[4] ^ data[5] ^ data[6];
    assign p3 = data[7] ^ data[6] ^ data[5] ^ data[4] ^ data[3] ^ data[2] ^ data[1] ^ data[0];
    
    // 计算总体奇偶校验位
    assign overall_parity = p0 ^ p1 ^ p2 ^ p3 ^ data[7] ^ data[6] ^ data[5] ^ data[4] ^ 
                           data[3] ^ data[2] ^ data[1] ^ data[0];
    
    // 按照汉明码格式组装输出
    assign code = {overall_parity, data[7:4], p3, data[3:1], p2, data[0], p1, p0};
endmodule