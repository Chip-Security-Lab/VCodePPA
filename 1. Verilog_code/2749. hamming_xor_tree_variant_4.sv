//SystemVerilog
module hamming_xor_tree(
    input [31:0] data,
    output [38:0] encoded
);
    // 计算奇偶校验位
    wire [5:0] parity;
    
    // 使用并行计算减少逻辑深度
    assign parity[0] = ^data[31:0];  // 总体奇偶校验
    assign parity[1] = ^data[31:16]; // 高16位奇偶校验
    assign parity[2] = ^data[15:8];  // 中间8位奇偶校验
    assign parity[3] = ^data[7:4];   // 低4位奇偶校验
    assign parity[4] = ^data[3:2];   // 最低2位奇偶校验
    assign parity[5] = data[1] ^ data[0]; // 最低位奇偶校验
    
    // 数据位直接映射
    assign encoded[38:7] = data;
    
    // 奇偶校验位分配
    assign encoded[6:1] = parity;
    assign encoded[0] = ^parity; // 总体奇偶校验
endmodule