//SystemVerilog
module hamming_encoder (
    input  wire [3:0] data_in,
    output wire [6:0] encoded_out
);
    // 优化的布尔表达式实现
    wire p1, p2, p4;
    
    // 直接使用data_in位，避免中间变量
    // 通过重用中间结果减少XOR操作数量
    wire d0_xor_d1 = data_in[0] ^ data_in[1];
    wire d2_xor_d3 = data_in[2] ^ data_in[3];
    
    assign p1 = d0_xor_d1 ^ data_in[3];
    assign p2 = data_in[0] ^ d2_xor_d3;
    assign p4 = data_in[1] ^ d2_xor_d3;
    
    // 使用拼接操作符直接构建输出
    assign encoded_out = {data_in[3], data_in[2], data_in[1], p4, data_in[0], p2, p1};
endmodule