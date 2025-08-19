//SystemVerilog
module hamming_decoder_lookup(
    input clk, en,
    input [11:0] codeword,
    output reg [7:0] data_out,
    output reg error
);
    reg [3:0] syndrome;
    reg [11:0] corrected;
    
    // 中间变量用于计算syndrome各位
    reg syndrome_bit0, syndrome_bit1, syndrome_bit2, syndrome_bit3;
    reg [11:0] corrected_tmp;
    reg syndrome_is_zero;
    
    always @(posedge clk) begin
        if (en) begin
            // 分解syndrome计算为多个简单步骤
            syndrome_bit0 = codeword[0] ^ codeword[2] ^ codeword[4] ^ codeword[6] ^ codeword[8] ^ codeword[10];
            syndrome_bit1 = codeword[1] ^ codeword[2] ^ codeword[5] ^ codeword[6] ^ codeword[9] ^ codeword[10];
            syndrome_bit2 = codeword[3] ^ codeword[4] ^ codeword[5] ^ codeword[6];
            syndrome_bit3 = codeword[7] ^ codeword[8] ^ codeword[9] ^ codeword[10];
            
            // 合并syndrome
            syndrome <= {syndrome_bit3, syndrome_bit2, syndrome_bit1, syndrome_bit0};
            
            // 简化错误检测
            syndrome_is_zero = (syndrome_bit3 == 1'b0) && 
                              (syndrome_bit2 == 1'b0) && 
                              (syndrome_bit1 == 1'b0) && 
                              (syndrome_bit0 == 1'b0);
            error <= !syndrome_is_zero;
            
            // 分解case语句为多级if结构
            corrected_tmp = codeword;
            
            // 处理bit0错误
            if (syndrome_bit3 == 1'b0 && syndrome_bit2 == 1'b0 && 
                syndrome_bit1 == 1'b0 && syndrome_bit0 == 1'b1) begin
                corrected_tmp[0] = ~codeword[0];
            end
            // 处理bit1错误
            else if (syndrome_bit3 == 1'b0 && syndrome_bit2 == 1'b0 && 
                    syndrome_bit1 == 1'b1 && syndrome_bit0 == 1'b0) begin
                corrected_tmp[1] = ~codeword[1];
            end
            // 处理bit2错误
            else if (syndrome_bit3 == 1'b0 && syndrome_bit2 == 1'b1 && 
                    syndrome_bit1 == 1'b0 && syndrome_bit0 == 1'b0) begin
                corrected_tmp[2] = ~codeword[2];
            end
            // 处理bit3错误
            else if (syndrome_bit3 == 1'b0 && syndrome_bit2 == 1'b1 && 
                    syndrome_bit1 == 1'b0 && syndrome_bit0 == 1'b1) begin
                corrected_tmp[3] = ~codeword[3];
            end
            
            corrected <= corrected_tmp;
            
            // 优化数据位提取
            if (syndrome_is_zero) begin
                data_out <= {codeword[10:7], codeword[6:4], codeword[2]};
            end else begin
                data_out <= {corrected_tmp[10:7], corrected_tmp[6:4], corrected_tmp[2]};
            end
        end
    end
endmodule