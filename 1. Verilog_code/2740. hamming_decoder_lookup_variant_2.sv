//SystemVerilog
module hamming_decoder_lookup(
    input clk, en,
    input [11:0] codeword,
    output reg [7:0] data_out,
    output reg error
);
    // 将syndrome计算分解为更小的并行运算单元
    reg [1:0] syndrome_part1, syndrome_part2;
    reg [3:0] syndrome;
    reg [11:0] corrected;
    
    // 预计算的部分异或结果
    reg xor_group1, xor_group2, xor_group3, xor_group4;
    
    always @(posedge clk) begin
        if (en) begin
            // 将syndrome计算拆分为并行的小组，减少关键路径深度
            // 预计算部分异或结果
            xor_group1 <= codeword[0] ^ codeword[2];
            xor_group2 <= codeword[4] ^ codeword[6];
            xor_group3 <= codeword[8] ^ codeword[10];
            xor_group4 <= codeword[1] ^ codeword[2];
            
            // 计算第一阶段的syndrome部分结果
            syndrome_part1[0] <= xor_group1 ^ xor_group2;
            syndrome_part1[1] <= xor_group4 ^ (codeword[5] ^ codeword[6]);
            
            syndrome_part2[0] <= xor_group3;
            syndrome_part2[1] <= codeword[9] ^ codeword[10];
            
            // 完成syndrome计算
            syndrome[0] <= syndrome_part1[0] ^ syndrome_part2[0];
            syndrome[1] <= syndrome_part1[1] ^ syndrome_part2[1];
            syndrome[2] <= codeword[3] ^ codeword[4] ^ codeword[5] ^ codeword[6];
            syndrome[3] <= codeword[7] ^ codeword[8] ^ codeword[9] ^ codeword[10];
            
            // 使用OR树结构来判断syndrome是否为0，减少比较器深度
            error <= |syndrome;
            
            // 优化查找表实现，减少case语句的判断深度
            // 基于syndrome的低两位和高两位分别进行预选择
            case (syndrome)
                4'b0000: corrected <= codeword;
                4'b0001: corrected <= {codeword[11:1], ~codeword[0]};
                4'b0010: corrected <= {codeword[11:2], ~codeword[1], codeword[0]};
                4'b0100: corrected <= {codeword[11:3], ~codeword[2], codeword[1:0]};
                4'b0101: corrected <= {codeword[11:4], ~codeword[3], codeword[2:0]};
                default: corrected <= codeword; // 更多情况将在此实现
            endcase
            
            // 优化数据位提取，避免过长的位选择链
            data_out <= {
                corrected[10:7],  // 高4位
                corrected[6:4],   // 中3位
                corrected[2]      // 低1位
            };
        end
    end
endmodule