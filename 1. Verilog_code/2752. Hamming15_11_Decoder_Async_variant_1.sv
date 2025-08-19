//SystemVerilog
// 顶层模块
module Hamming15_11_Decoder_Async (
    input [14:0] encoded_data,    // 15位含错编码
    output [10:0] corrected_data, // 11位纠正后数据
    output [3:0] error_pos        // 错误位置指示
);
    // 错误检测子模块
    wire [3:0] syndrome;
    Hamming_Syndrome_Calculator syndrome_calc (
        .encoded_data(encoded_data),
        .syndrome(syndrome)
    );
    
    // 错误纠正子模块
    Hamming_Error_Corrector error_corrector (
        .encoded_data(encoded_data),
        .syndrome(syndrome),
        .corrected_data(corrected_data)
    );
    
    // 直接将综合体错误指示连接到输出
    assign error_pos = syndrome;
endmodule

// 简化后的校验位计算子模块
module Hamming_Syndrome_Calculator (
    input [14:0] encoded_data,
    output [3:0] syndrome
);
    // 优化的校验位计算 - 直接使用异或运算，无需子模块调用
    assign syndrome[0] = encoded_data[0] ^ encoded_data[2] ^ encoded_data[4] ^ 
                        encoded_data[6] ^ encoded_data[8] ^ encoded_data[10] ^ 
                        encoded_data[12] ^ encoded_data[14];
                        
    assign syndrome[1] = encoded_data[1] ^ encoded_data[2] ^ encoded_data[5] ^ 
                        encoded_data[6] ^ encoded_data[9] ^ encoded_data[10] ^ 
                        encoded_data[13] ^ encoded_data[14];
                        
    assign syndrome[2] = encoded_data[3] ^ encoded_data[4] ^ encoded_data[5] ^ 
                        encoded_data[6] ^ encoded_data[11] ^ encoded_data[12] ^ 
                        encoded_data[13] ^ encoded_data[14];
                        
    assign syndrome[3] = encoded_data[7] ^ encoded_data[8] ^ encoded_data[9] ^ 
                        encoded_data[10] ^ encoded_data[11] ^ encoded_data[12] ^ 
                        encoded_data[13] ^ encoded_data[14];
endmodule

// 错误纠正子模块 - 简化实现
module Hamming_Error_Corrector (
    input [14:0] encoded_data,
    input [3:0] syndrome,
    output [10:0] corrected_data
);
    // 从编码数据中提取信息位
    wire [10:0] extracted_data = {encoded_data[14:8], encoded_data[6:4], encoded_data[2]};
    
    // 直接计算错误掩码并应用纠错 - 无需额外模块
    reg [10:0] error_mask;
    
    always @(*) begin
        error_mask = 11'b0;
        if (|syndrome) begin // 有错误时
            case (syndrome)
                // 信息位对应的错误模式 - 只处理需要纠正的位
                4'h2:  error_mask[0] = 1'b1;  // 位置2对应d1
                4'h4:  error_mask[1] = 1'b1;  // 位置4对应d2
                4'h5:  error_mask[2] = 1'b1;  // 位置5对应d3
                4'h6:  error_mask[3] = 1'b1;  // 位置6对应d4
                4'h8:  error_mask[4] = 1'b1;  // 位置8对应d5
                4'h9:  error_mask[5] = 1'b1;  // 位置9对应d6
                4'ha:  error_mask[6] = 1'b1;  // 位置10对应d7
                4'hb:  error_mask[7] = 1'b1;  // 位置11对应d8
                4'hc:  error_mask[8] = 1'b1;  // 位置12对应d9
                4'hd:  error_mask[9] = 1'b1;  // 位置13对应d10
                4'he:  error_mask[10] = 1'b1; // 位置14对应d11
                default: error_mask = 11'b0;  // 校验位错误或无错误
            endcase
        end
    end
    
    // 应用错误掩码纠正数据
    assign corrected_data = extracted_data ^ error_mask;
endmodule