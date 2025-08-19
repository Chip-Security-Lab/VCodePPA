//SystemVerilog
// 顶层模块
module async_crc4(
    input wire [3:0] data_in,
    output wire [3:0] crc_out
);
    parameter [3:0] POLYNOMIAL = 4'h3; // x^4 + x + 1
    
    // 直接计算CRC逻辑，移除了子模块的不必要层次
    // 根据布尔代数简化了表达式
    assign crc_out[0] = data_in[0] ^ data_in[3];
    assign crc_out[1] = data_in[1] ^ data_in[0] ^ data_in[3];
    assign crc_out[2] = data_in[2] ^ data_in[1] ^ data_in[0] ^ data_in[3];
    assign crc_out[3] = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];
endmodule