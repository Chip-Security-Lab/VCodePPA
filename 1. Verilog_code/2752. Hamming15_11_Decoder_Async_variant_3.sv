//SystemVerilog
module Hamming15_11_Decoder_Async (
    input [14:0] encoded_data,  // 15位含错编码
    output [10:0] corrected_data, // 11位纠正后数据
    output [3:0] error_pos       // 错误位置指示
);
    // 计算奇偶校验位
    wire p1, p2, p4, p8;
    
    // 使用更高效的奇偶校验计算方法
    // p1 (位置1) - 检查位置3,5,7,9,11,13,15的奇偶性
    assign p1 = encoded_data[0] ^ encoded_data[2] ^ encoded_data[4] ^ 
                encoded_data[6] ^ encoded_data[8] ^ encoded_data[10] ^ 
                encoded_data[12] ^ encoded_data[14];
                
    // p2 (位置2) - 检查位置3,6,7,10,11,14,15的奇偶性
    assign p2 = encoded_data[1] ^ encoded_data[2] ^ encoded_data[5] ^ 
                encoded_data[6] ^ encoded_data[9] ^ encoded_data[10] ^ 
                encoded_data[13] ^ encoded_data[14];
                
    // p4 (位置4) - 检查位置5,6,7,12,13,14,15的奇偶性
    assign p4 = encoded_data[3] ^ encoded_data[4] ^ encoded_data[5] ^ 
                encoded_data[6] ^ encoded_data[11] ^ encoded_data[12] ^ 
                encoded_data[13] ^ encoded_data[14];
                
    // p8 (位置8) - 检查位置9,10,11,12,13,14,15的奇偶性
    assign p8 = encoded_data[7] ^ encoded_data[8] ^ encoded_data[9] ^ 
                encoded_data[10] ^ encoded_data[11] ^ encoded_data[12] ^ 
                encoded_data[13] ^ encoded_data[14];
    
    // 错误位置计算
    assign error_pos = {p8, p4, p2, p1};
    
    // 提取原始数据位
    wire [10:0] raw_data = {encoded_data[14:7], encoded_data[3], encoded_data[2], encoded_data[1]};
    
    // 使用移位和条件赋值来优化错误纠正逻辑
    wire [14:0] corrected_encoded;
    assign corrected_encoded = (|error_pos) ? (encoded_data ^ (15'b1 << (error_pos - 1))) : encoded_data;
    
    // 从纠正后的编码中提取数据位
    assign corrected_data = {corrected_encoded[14:7], corrected_encoded[3], corrected_encoded[2], corrected_encoded[1]};
endmodule