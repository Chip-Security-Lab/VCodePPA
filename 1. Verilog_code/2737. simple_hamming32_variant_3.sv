//SystemVerilog
module simple_hamming32(
    input [31:0] data_in,
    output [38:0] data_out
);
    wire [5:0] parity;
    wire [15:0] partial_parity0, partial_parity1;
    wire [7:0] partial_parity2, partial_parity3;
    wire [3:0] partial_parity4, partial_parity5;
    
    // 优化的奇偶校验计算 - 使用分层异或减少树深度
    // 将大的异或操作分解为更小的并行计算单元
    
    // 优化 parity[0]
    assign partial_parity0[0] = data_in[0] ^ data_in[2] ^ data_in[4] ^ data_in[6] ^ data_in[8] ^ data_in[10] ^ data_in[12] ^ data_in[14];
    assign partial_parity0[1] = data_in[16] ^ data_in[18] ^ data_in[20] ^ data_in[22] ^ data_in[24] ^ data_in[26] ^ data_in[28] ^ data_in[30];
    assign parity[0] = partial_parity0[0] ^ partial_parity0[1];
    
    // 优化 parity[1]
    assign partial_parity1[0] = data_in[1] ^ data_in[2] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[10] ^ data_in[13] ^ data_in[14];
    assign partial_parity1[1] = data_in[17] ^ data_in[18] ^ data_in[21] ^ data_in[22] ^ data_in[25] ^ data_in[26] ^ data_in[29] ^ data_in[30];
    assign parity[1] = partial_parity1[0] ^ partial_parity1[1];
    
    // 优化 parity[2]
    assign partial_parity2[0] = data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14];
    assign partial_parity2[1] = data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30];
    assign parity[2] = partial_parity2[0] ^ partial_parity2[1];
    
    // 优化 parity[3]
    assign partial_parity3[0] = data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14];
    assign partial_parity3[1] = data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30];
    assign parity[3] = partial_parity3[0] ^ partial_parity3[1];
    
    // 优化 parity[4]
    assign partial_parity4[0] = data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22];
    assign partial_parity4[1] = data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30];
    assign parity[4] = partial_parity4[0] ^ partial_parity4[1];
    
    // 优化 parity[5]
    assign partial_parity5[0] = data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    assign partial_parity5[1] = data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[15];
    assign partial_parity5[2] = data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[23];
    assign partial_parity5[3] = data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30];
    assign parity[5] = partial_parity5[0] ^ partial_parity5[1] ^ partial_parity5[2] ^ partial_parity5[3];
    
    // 组装输出
    assign data_out = {data_in, parity, 1'b0};
endmodule