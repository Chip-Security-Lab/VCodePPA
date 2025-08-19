//SystemVerilog
module usb_crc16_gen(
    input [7:0] data_in,
    input [15:0] crc_in,
    output [15:0] crc_out
);
    // 直接将CRC计算合并到顶层模块，消除不必要的中间层级
    assign crc_out = {
        // 高字节 (优化后)
        data_in[7] ^ crc_in[13] ^ crc_in[7] ^ data_in[0] ^ crc_in[0],
        data_in[6] ^ crc_in[12] ^ crc_in[6],
        data_in[5] ^ crc_in[11] ^ crc_in[5],
        data_in[4] ^ crc_in[10] ^ crc_in[4],
        data_in[3] ^ crc_in[9] ^ crc_in[3],
        data_in[2] ^ crc_in[8] ^ crc_in[2],
        data_in[1] ^ crc_in[7] ^ crc_in[1],
        data_in[0] ^ crc_in[6] ^ crc_in[0],
        
        // 低字节 (优化后)
        data_in[7] ^ crc_in[5] ^ crc_in[15],
        data_in[7] ^ data_in[6] ^ crc_in[4] ^ crc_in[14] ^ crc_in[15],
        data_in[7] ^ data_in[6] ^ data_in[5] ^ crc_in[3] ^ crc_in[13] ^ crc_in[14] ^ crc_in[15],
        data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ crc_in[2] ^ crc_in[12] ^ crc_in[13] ^ crc_in[14] ^ crc_in[15],
        data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[3] ^ crc_in[1] ^ crc_in[11] ^ crc_in[12] ^ crc_in[13] ^ crc_in[14] ^ crc_in[15],
        data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ crc_in[0] ^ crc_in[10] ^ crc_in[11] ^ crc_in[12] ^ crc_in[13] ^ crc_in[14] ^ crc_in[15],
        data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ data_in[1] ^ crc_in[9] ^ crc_in[10] ^ crc_in[11] ^ crc_in[12] ^ crc_in[13] ^ crc_in[14] ^ crc_in[15],
        data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0] ^ crc_in[8] ^ crc_in[9] ^ crc_in[10] ^ crc_in[11] ^ crc_in[12] ^ crc_in[13] ^ crc_in[14] ^ crc_in[15]
    };
endmodule