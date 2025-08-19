//SystemVerilog
module async_crc4(
    input wire [3:0] data_in,
    output wire [3:0] crc_out
);
    // 直接在顶层模块中实现计算逻辑，省去了子模块的开销
    // 根据数学展开简化表达式
    assign crc_out[0] = data_in[0] ^ data_in[3];
    assign crc_out[1] = data_in[1] ^ data_in[0] ^ data_in[3];
    assign crc_out[2] = data_in[2] ^ data_in[1] ^ data_in[0] ^ data_in[3];
    assign crc_out[3] = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];
endmodule