//SystemVerilog
module Hamming15_11_Decoder_Async (
    input [14:0] encoded_data,  // 15位含错编码
    output [10:0] corrected_data, // 11位纠正后数据
    output [3:0] error_pos       // 错误位置指示
);
    // 计算奇偶校验位
    wire p1 = ^{encoded_data[0], encoded_data[2], encoded_data[4], encoded_data[6], 
               encoded_data[8], encoded_data[10], encoded_data[12], encoded_data[14]};
    wire p2 = ^{encoded_data[1], encoded_data[2], encoded_data[5], encoded_data[6], 
               encoded_data[9], encoded_data[10], encoded_data[13], encoded_data[14]};
    wire p4 = ^{encoded_data[3], encoded_data[4], encoded_data[5], encoded_data[6], 
               encoded_data[11], encoded_data[12], encoded_data[13], encoded_data[14]};
    wire p8 = ^{encoded_data[7], encoded_data[8], encoded_data[9], encoded_data[10], 
               encoded_data[11], encoded_data[12], encoded_data[13], encoded_data[14]};
               
    // 错误位置的综合
    assign error_pos = {p8, p4, p2, p1};
    
    // 提取原始数据位
    wire [10:0] original_data = {encoded_data[14:7], encoded_data[6:3], encoded_data[1]};
    
    // 使用查找表实现错误位置到纠正掩码的映射
    reg [10:0] correction_mask;
    
    always @(*) begin
        case (error_pos)
            4'b0000: correction_mask = 11'b00000000000; // 无错误
            4'b0001: correction_mask = 11'b00000000000; // 位置1 (校验位错误)
            4'b0010: correction_mask = 11'b00000000000; // 位置2 (校验位错误)
            4'b0011: correction_mask = 11'b00000000001; // 位置3 (数据位错误)
            4'b0100: correction_mask = 11'b00000000000; // 位置4 (校验位错误)
            4'b0101: correction_mask = 11'b00000000010; // 位置5 (数据位错误)
            4'b0110: correction_mask = 11'b00000000100; // 位置6 (数据位错误)
            4'b0111: correction_mask = 11'b00000001000; // 位置7 (数据位错误)
            4'b1000: correction_mask = 11'b00000000000; // 位置8 (校验位错误)
            4'b1001: correction_mask = 11'b00000010000; // 位置9 (数据位错误)
            4'b1010: correction_mask = 11'b00000100000; // 位置10 (数据位错误)
            4'b1011: correction_mask = 11'b00001000000; // 位置11 (数据位错误)
            4'b1100: correction_mask = 11'b00010000000; // 位置12 (数据位错误)
            4'b1101: correction_mask = 11'b00100000000; // 位置13 (数据位错误)
            4'b1110: correction_mask = 11'b01000000000; // 位置14 (数据位错误)
            4'b1111: correction_mask = 11'b10000000000; // 位置15 (数据位错误)
        endcase
    end
    
    // 应用纠错掩码
    assign corrected_data = original_data ^ correction_mask;
    
endmodule