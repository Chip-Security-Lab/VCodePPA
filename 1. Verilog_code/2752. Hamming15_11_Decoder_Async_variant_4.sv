//SystemVerilog
module Hamming15_11_Decoder_Async (
    input [14:0] encoded_data,  // 15位含错编码
    output [10:0] corrected_data, // 11位纠正后数据
    output [3:0] error_pos       // 错误位置指示
);
    // 计算奇偶校验位
    wire p1, p2, p4, p8;
    wire [10:0] data_bits;
    wire [10:0] corrected_bits;
    wire error_detected;
    wire [14:0] error_mask;
    wire [14:0] actual_error_mask;
    
    // 将数据位提取出来，便于后续处理
    assign data_bits = {encoded_data[14:7], encoded_data[6:3], encoded_data[1]};
    
    // 分解复杂的校验位计算为多个简单运算
    assign p1 = encoded_data[0] ^ encoded_data[2] ^ encoded_data[4] ^ encoded_data[6] ^ 
                encoded_data[8] ^ encoded_data[10] ^ encoded_data[12] ^ encoded_data[14];
    
    assign p2 = encoded_data[1] ^ encoded_data[2] ^ encoded_data[5] ^ encoded_data[6] ^ 
                encoded_data[9] ^ encoded_data[10] ^ encoded_data[13] ^ encoded_data[14];
    
    assign p4 = encoded_data[3] ^ encoded_data[4] ^ encoded_data[5] ^ encoded_data[6] ^ 
                encoded_data[11] ^ encoded_data[12] ^ encoded_data[13] ^ encoded_data[14];
    
    assign p8 = encoded_data[7] ^ encoded_data[8] ^ encoded_data[9] ^ encoded_data[10] ^ 
                encoded_data[11] ^ encoded_data[12] ^ encoded_data[13] ^ encoded_data[14];
    
    // 错误位置指示
    assign error_pos = {p8, p4, p2, p1};
    
    // 检测是否有错误
    assign error_detected = |error_pos;
    
    // 初始化错误掩码
    assign error_mask = (1'b1 << (4'd15 - error_pos));
    
    // 只有当检测到错误时才应用掩码
    assign actual_error_mask = error_detected ? error_mask : 15'b0;
    
    // 纠正操作：针对不同情况分别处理
    // 提取对应位并根据掩码进行纠正
    assign corrected_bits[10] = data_bits[10] ^ (error_detected && (error_pos == 4'd15)); // 位14
    assign corrected_bits[9] = data_bits[9] ^ (error_detected && (error_pos == 4'd14));   // 位13
    assign corrected_bits[8] = data_bits[8] ^ (error_detected && (error_pos == 4'd13));   // 位12
    assign corrected_bits[7] = data_bits[7] ^ (error_detected && (error_pos == 4'd12));   // 位11
    assign corrected_bits[6] = data_bits[6] ^ (error_detected && (error_pos == 4'd11));   // 位10
    assign corrected_bits[5] = data_bits[5] ^ (error_detected && (error_pos == 4'd10));   // 位9
    assign corrected_bits[4] = data_bits[4] ^ (error_detected && (error_pos == 4'd9));    // 位8
    assign corrected_bits[3] = data_bits[3] ^ (error_detected && (error_pos == 4'd7));    // 位6
    assign corrected_bits[2] = data_bits[2] ^ (error_detected && (error_pos == 4'd6));    // 位5
    assign corrected_bits[1] = data_bits[1] ^ (error_detected && (error_pos == 4'd5));    // 位4
    assign corrected_bits[0] = data_bits[0] ^ (error_detected && (error_pos == 4'd3));    // 位2
    
    // 最终的纠正数据
    assign corrected_data = corrected_bits;
    
endmodule