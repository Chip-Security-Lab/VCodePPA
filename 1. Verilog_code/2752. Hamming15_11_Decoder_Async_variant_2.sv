//SystemVerilog
//=============================================================================
// 顶层模块：汉明(15,11)解码器
//=============================================================================
module Hamming15_11_Decoder_Async (
    input [14:0] encoded_data,     // 15位含错编码
    output [10:0] corrected_data,  // 11位纠正后数据
    output [3:0] error_pos         // 错误位置指示
);
    // 内部连线
    wire [3:0] syndrome;
    wire [14:0] data_with_error_bit;
    wire error_detected;
    
    // 实例化子模块
    Syndrome_Calculator syndrome_calc (
        .encoded_data(encoded_data),
        .syndrome(syndrome)
    );
    
    Error_Detector error_detect (
        .syndrome(syndrome),
        .error_detected(error_detected)
    );
    
    Error_Corrector error_correct (
        .encoded_data(encoded_data),
        .syndrome(syndrome),
        .error_detected(error_detected),
        .data_with_error_bit(data_with_error_bit)
    );
    
    Data_Extractor data_extract (
        .data_with_error_bit(data_with_error_bit),
        .corrected_data(corrected_data)
    );
    
    // 直接从综合症输出错误位置
    assign error_pos = syndrome;
    
endmodule

//=============================================================================
// 子模块1：计算综合症
//=============================================================================
module Syndrome_Calculator (
    input [14:0] encoded_data,
    output [3:0] syndrome
);
    // 计算奇偶校验位
    wire p1, p2, p4, p8;
    
    assign p1 = encoded_data[0] ^ encoded_data[2] ^ encoded_data[4] ^ encoded_data[6] 
              ^ encoded_data[8] ^ encoded_data[10] ^ encoded_data[12] ^ encoded_data[14];
              
    assign p2 = encoded_data[1] ^ encoded_data[2] ^ encoded_data[5] ^ encoded_data[6] 
              ^ encoded_data[9] ^ encoded_data[10] ^ encoded_data[13] ^ encoded_data[14];
              
    assign p4 = encoded_data[3] ^ encoded_data[4] ^ encoded_data[5] ^ encoded_data[6] 
              ^ encoded_data[11] ^ encoded_data[12] ^ encoded_data[13] ^ encoded_data[14];
              
    assign p8 = encoded_data[7] ^ encoded_data[8] ^ encoded_data[9] ^ encoded_data[10] 
              ^ encoded_data[11] ^ encoded_data[12] ^ encoded_data[13] ^ encoded_data[14];
    
    // 综合症是错误位置的二进制表示
    assign syndrome = {p8, p4, p2, p1};
    
endmodule

//=============================================================================
// 子模块2：检测是否有错误
//=============================================================================
module Error_Detector (
    input [3:0] syndrome,
    output error_detected
);
    // 如果综合症不为0，则检测到错误
    assign error_detected = |syndrome;
    
endmodule

//=============================================================================
// 子模块3：错误纠正
//=============================================================================
module Error_Corrector (
    input [14:0] encoded_data,
    input [3:0] syndrome,
    input error_detected,
    output [14:0] data_with_error_bit
);
    // 生成错误掩码
    wire [14:0] error_mask;
    
    // 仅当检测到错误时生成错误掩码，否则为0
    assign error_mask = error_detected ? (15'b1 << (15 - syndrome)) : 15'b0;
    
    // 纠正错误位
    assign data_with_error_bit = encoded_data ^ error_mask;
    
endmodule

//=============================================================================
// 子模块4：数据提取器
//=============================================================================
module Data_Extractor (
    input [14:0] data_with_error_bit,
    output [10:0] corrected_data
);
    // 从汉明码中提取有效数据位
    assign corrected_data = {data_with_error_bit[14:7], data_with_error_bit[6:3], data_with_error_bit[1]};
    
endmodule