//SystemVerilog
module parallel_crc32(
    input wire clock,
    input wire clear,
    input wire [31:0] data_word,
    input wire word_valid,
    output reg [31:0] crc_value
);
    localparam POLY = 32'h04C11DB7;
    
    // 预计算常量以减少关键路径延迟
    wire [31:0] poly_shifted_1 = POLY >> 1;
    wire [31:0] poly_shifted_2 = POLY >> 2;
    wire [31:0] poly_shifted_3 = POLY >> 3;
    wire [31:0] poly_shifted_4 = POLY >> 4;
    wire [31:0] poly_shifted_5 = POLY >> 5;
    wire [31:0] poly_shifted_6 = POLY >> 6;
    wire [31:0] poly_shifted_7 = POLY >> 7;
    
    // 分割数据字以并行处理
    wire [7:0] data_byte0 = data_word[31:24];
    wire [7:0] data_byte1 = data_word[23:16];
    wire [7:0] data_byte2 = data_word[15:8];
    wire [7:0] data_byte3 = data_word[7:0];
    
    // 每个字节的多路复用器预计算
    wire [31:0] byte0_mux_0 = data_byte0[7] ? POLY : 32'h0;
    wire [31:0] byte0_mux_1 = data_byte0[6] ? poly_shifted_1 : 32'h0;
    wire [31:0] byte0_mux_2 = data_byte0[5] ? poly_shifted_2 : 32'h0;
    wire [31:0] byte0_mux_3 = data_byte0[4] ? poly_shifted_3 : 32'h0;
    wire [31:0] byte0_mux_4 = data_byte0[3] ? poly_shifted_4 : 32'h0;
    wire [31:0] byte0_mux_5 = data_byte0[2] ? poly_shifted_5 : 32'h0;
    wire [31:0] byte0_mux_6 = data_byte0[1] ? poly_shifted_6 : 32'h0;
    wire [31:0] byte0_mux_7 = data_byte0[0] ? poly_shifted_7 : 32'h0;
    
    wire [31:0] byte1_mux_0 = data_byte1[7] ? POLY : 32'h0;
    wire [31:0] byte1_mux_1 = data_byte1[6] ? poly_shifted_1 : 32'h0;
    wire [31:0] byte1_mux_2 = data_byte1[5] ? poly_shifted_2 : 32'h0;
    wire [31:0] byte1_mux_3 = data_byte1[4] ? poly_shifted_3 : 32'h0;
    wire [31:0] byte1_mux_4 = data_byte1[3] ? poly_shifted_4 : 32'h0;
    wire [31:0] byte1_mux_5 = data_byte1[2] ? poly_shifted_5 : 32'h0;
    wire [31:0] byte1_mux_6 = data_byte1[1] ? poly_shifted_6 : 32'h0;
    wire [31:0] byte1_mux_7 = data_byte1[0] ? poly_shifted_7 : 32'h0;
    
    wire [31:0] byte2_mux_0 = data_byte2[7] ? POLY : 32'h0;
    wire [31:0] byte2_mux_1 = data_byte2[6] ? poly_shifted_1 : 32'h0;
    wire [31:0] byte2_mux_2 = data_byte2[5] ? poly_shifted_2 : 32'h0;
    wire [31:0] byte2_mux_3 = data_byte2[4] ? poly_shifted_3 : 32'h0;
    wire [31:0] byte2_mux_4 = data_byte2[3] ? poly_shifted_4 : 32'h0;
    wire [31:0] byte2_mux_5 = data_byte2[2] ? poly_shifted_5 : 32'h0;
    wire [31:0] byte2_mux_6 = data_byte2[1] ? poly_shifted_6 : 32'h0;
    wire [31:0] byte2_mux_7 = data_byte2[0] ? poly_shifted_7 : 32'h0;
    
    wire [31:0] byte3_mux_0 = data_byte3[7] ? POLY : 32'h0;
    wire [31:0] byte3_mux_1 = data_byte3[6] ? poly_shifted_1 : 32'h0;
    wire [31:0] byte3_mux_2 = data_byte3[5] ? poly_shifted_2 : 32'h0;
    wire [31:0] byte3_mux_3 = data_byte3[4] ? poly_shifted_3 : 32'h0;
    wire [31:0] byte3_mux_4 = data_byte3[3] ? poly_shifted_4 : 32'h0;
    wire [31:0] byte3_mux_5 = data_byte3[2] ? poly_shifted_5 : 32'h0;
    wire [31:0] byte3_mux_6 = data_byte3[1] ? poly_shifted_6 : 32'h0;
    wire [31:0] byte3_mux_7 = data_byte3[0] ? poly_shifted_7 : 32'h0;
    
    // 平衡的树结构XOR操作，减少关键路径延迟
    wire [31:0] crc_shifted = crc_value << 8;
    
    // 字节0的平衡树级联XOR操作
    wire [31:0] byte0_xor_01 = byte0_mux_0 ^ byte0_mux_1;
    wire [31:0] byte0_xor_23 = byte0_mux_2 ^ byte0_mux_3;
    wire [31:0] byte0_xor_45 = byte0_mux_4 ^ byte0_mux_5;
    wire [31:0] byte0_xor_67 = byte0_mux_6 ^ byte0_mux_7;
    
    wire [31:0] byte0_xor_0123 = byte0_xor_01 ^ byte0_xor_23;
    wire [31:0] byte0_xor_4567 = byte0_xor_45 ^ byte0_xor_67;
    
    wire [31:0] byte0_all_xor = byte0_xor_0123 ^ byte0_xor_4567;
    wire [31:0] byte0_result = crc_shifted ^ byte0_all_xor;
    
    // 字节1的平衡树级联XOR操作
    wire [31:0] byte1_xor_01 = byte1_mux_0 ^ byte1_mux_1;
    wire [31:0] byte1_xor_23 = byte1_mux_2 ^ byte1_mux_3;
    wire [31:0] byte1_xor_45 = byte1_mux_4 ^ byte1_mux_5;
    wire [31:0] byte1_xor_67 = byte1_mux_6 ^ byte1_mux_7;
    
    wire [31:0] byte1_xor_0123 = byte1_xor_01 ^ byte1_xor_23;
    wire [31:0] byte1_xor_4567 = byte1_xor_45 ^ byte1_xor_67;
    
    wire [31:0] byte1_all_xor = byte1_xor_0123 ^ byte1_xor_4567;
    wire [31:0] byte1_shifted = byte0_result << 8;
    wire [31:0] byte1_result = byte1_shifted ^ byte1_all_xor;
    
    // 字节2的平衡树级联XOR操作
    wire [31:0] byte2_xor_01 = byte2_mux_0 ^ byte2_mux_1;
    wire [31:0] byte2_xor_23 = byte2_mux_2 ^ byte2_mux_3;
    wire [31:0] byte2_xor_45 = byte2_mux_4 ^ byte2_mux_5;
    wire [31:0] byte2_xor_67 = byte2_mux_6 ^ byte2_mux_7;
    
    wire [31:0] byte2_xor_0123 = byte2_xor_01 ^ byte2_xor_23;
    wire [31:0] byte2_xor_4567 = byte2_xor_45 ^ byte2_xor_67;
    
    wire [31:0] byte2_all_xor = byte2_xor_0123 ^ byte2_xor_4567;
    wire [31:0] byte2_shifted = byte1_result << 8;
    wire [31:0] byte2_result = byte2_shifted ^ byte2_all_xor;
    
    // 字节3的平衡树级联XOR操作
    wire [31:0] byte3_xor_01 = byte3_mux_0 ^ byte3_mux_1;
    wire [31:0] byte3_xor_23 = byte3_mux_2 ^ byte3_mux_3;
    wire [31:0] byte3_xor_45 = byte3_mux_4 ^ byte3_mux_5;
    wire [31:0] byte3_xor_67 = byte3_mux_6 ^ byte3_mux_7;
    
    wire [31:0] byte3_xor_0123 = byte3_xor_01 ^ byte3_xor_23;
    wire [31:0] byte3_xor_4567 = byte3_xor_45 ^ byte3_xor_67;
    
    wire [31:0] byte3_all_xor = byte3_xor_0123 ^ byte3_xor_4567;
    wire [31:0] byte3_shifted = byte2_result << 8;
    wire [31:0] next_crc = byte3_shifted ^ byte3_all_xor;
    
    always @(posedge clock) begin
        if (clear) 
            crc_value <= 32'hFFFFFFFF;
        else if (word_valid) 
            crc_value <= next_crc;
    end
endmodule