//SystemVerilog
module hamming_encoder_self_test(
    input clk, rst, test_mode,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg test_pass
);
    reg [3:0] test_vector;
    reg [6:0] expected_code;
    
    // 流水线寄存器
    reg [3:0] test_vector_pipe;
    reg [3:0] data_in_pipe;
    reg test_mode_pipe;
    
    // 中间计算结果寄存器
    reg [2:0] parity_bits;
    reg [2:0] expected_parity;
    
    // 第一级流水线 - 寄存输入和中间计算结果
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            test_vector_pipe <= 4'b0;
            data_in_pipe <= 4'b0;
            test_mode_pipe <= 1'b0;
            test_vector <= 4'b0;
            parity_bits <= 3'b0;
            expected_parity <= 3'b0;
        end else begin
            test_mode_pipe <= test_mode;
            
            if (test_mode) begin
                // 更新测试向量
                test_vector <= test_vector + 1;
                test_vector_pipe <= test_vector;
                
                // 计算奇偶位 - 第一级
                parity_bits[0] <= test_vector[0] ^ test_vector[1] ^ test_vector[3];
                parity_bits[1] <= test_vector[0] ^ test_vector[2] ^ test_vector[3];
                parity_bits[2] <= test_vector[1] ^ test_vector[2] ^ test_vector[3];
                
                // 计算期望奇偶位 - 用于测试
                expected_parity[0] <= test_vector[0] ^ test_vector[1] ^ test_vector[3];
                expected_parity[1] <= test_vector[0] ^ test_vector[2] ^ test_vector[3];
                expected_parity[2] <= test_vector[1] ^ test_vector[2] ^ test_vector[3];
            end else begin
                data_in_pipe <= data_in;
                
                // 计算奇偶位 - 正常操作模式
                parity_bits[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
                parity_bits[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
                parity_bits[2] <= data_in[1] ^ data_in[2] ^ data_in[3];
            end
        end
    end
    
    // 第二级流水线 - 组合最终编码和测试结果
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            test_pass <= 1'b0;
            expected_code <= 7'b0;
        end else begin
            if (test_mode_pipe) begin
                // 完成编码
                encoded[0] <= parity_bits[0];
                encoded[1] <= parity_bits[1];
                encoded[2] <= test_vector_pipe[0];
                encoded[3] <= parity_bits[2];
                encoded[4] <= test_vector_pipe[1];
                encoded[5] <= test_vector_pipe[2];
                encoded[6] <= test_vector_pipe[3];
                
                // 设置期望编码
                expected_code[0] <= expected_parity[0];
                expected_code[1] <= expected_parity[1];
                expected_code[2] <= test_vector_pipe[0];
                expected_code[3] <= expected_parity[2];
                expected_code[4] <= test_vector_pipe[1];
                expected_code[5] <= test_vector_pipe[2];
                expected_code[6] <= test_vector_pipe[3];
                
                // 检查编码是否匹配期望
                test_pass <= (encoded == expected_code);
            end else begin
                // 完成编码 - 正常操作模式
                encoded[0] <= parity_bits[0];
                encoded[1] <= parity_bits[1];
                encoded[2] <= data_in_pipe[0];
                encoded[3] <= parity_bits[2];
                encoded[4] <= data_in_pipe[1];
                encoded[5] <= data_in_pipe[2];
                encoded[6] <= data_in_pipe[3];
            end
        end
    end
endmodule