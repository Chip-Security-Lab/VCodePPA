//SystemVerilog
module BIST_Hamming_Codec(
    input clk,
    input test_en,
    output reg test_pass
);
    reg [3:0] test_pattern;
    reg [6:0] encoded;
    reg [3:0] decoded;
    
    // 添加流水线寄存器
    reg [3:0] test_pattern_pipe;
    reg [6:0] encoded_pipe;
    reg [3:0] decoded_pipe;
    reg test_valid_pipe1, test_valid_pipe2;
    
    // 移除了initial块，改为复位值赋值
    always @(posedge clk) begin
        if(!test_en) begin
            test_pass <= 1'b1;
            test_pattern <= 4'b0000;
            test_valid_pipe1 <= 1'b0;
            test_valid_pipe2 <= 1'b0;
        end else begin
            // 第一级流水线：生成测试模式并编码
            test_pattern <= test_pattern + 1;
            encoded <= Hamming7_4_Encoder(test_pattern);
            test_pattern_pipe <= test_pattern;
            test_valid_pipe1 <= 1'b1;
            
            // 第二级流水线：解码
            decoded <= HammingDecoder(encoded);
            encoded_pipe <= encoded;
            test_pattern_pipe <= test_pattern_pipe;
            test_valid_pipe2 <= test_valid_pipe1;
            
            // 第三级流水线：比较结果
            if(test_valid_pipe2 && (decoded !== test_pattern_pipe))
                test_pass <= 1'b0;
        end
    end
    
    // 优化编码函数的实现 - 将复杂计算分拆为中间变量降低组合逻辑深度
    function [6:0] Hamming7_4_Encoder;
        input [3:0] data;
        reg p1_part1, p2_part1;
        begin
            // 将数据直接赋值
            Hamming7_4_Encoder[3:0] = data;
            
            // 计算奇偶位 - 拆分复杂的XOR运算链
            p1_part1 = data[0] ^ data[1];
            Hamming7_4_Encoder[4] = p1_part1 ^ data[3];
            
            p2_part1 = data[0] ^ data[2];
            Hamming7_4_Encoder[5] = p2_part1 ^ data[3];
            
            // 简化最后一个奇偶位计算
            Hamming7_4_Encoder[6] = data[1] ^ data[2] ^ data[3];
        end
    endfunction
    
    // 改进解码函数 - 实现真正的Hamming解码功能
    function [3:0] HammingDecoder;
        input [6:0] code;
        reg [2:0] syndrome;
        begin
            // 计算综合征码，拆分为多步以减少组合逻辑深度
            syndrome[0] = code[0] ^ code[2] ^ code[4] ^ code[6];
            syndrome[1] = code[1] ^ code[2] ^ code[5] ^ code[6];
            syndrome[2] = code[3] ^ code[4] ^ code[5] ^ code[6];
            
            // 默认情况下直接使用输入数据位
            HammingDecoder = code[3:0];
            
            // 只有当综合征码非零时才进行错误校正
            if(syndrome != 3'b000) begin
                // 如果检测到错误，则根据综合征码进行修正
                case(syndrome)
                    3'b001: HammingDecoder[0] = ~code[0];
                    3'b010: HammingDecoder[1] = ~code[1];
                    3'b011: HammingDecoder[2] = ~code[2];
                    3'b100: HammingDecoder[3] = ~code[3];
                    default: HammingDecoder = code[3:0]; // 其他情况保持不变
                endcase
            end
        end
    endfunction
endmodule