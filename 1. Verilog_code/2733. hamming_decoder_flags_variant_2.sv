//SystemVerilog
module hamming_decoder_flags(
    input clk, rst_n,
    // 数据输入接口 - Valid-Ready握手协议
    input [11:0] code_word,
    input code_valid,
    output reg code_ready,
    // 数据输出接口 - Valid-Ready握手协议
    output reg [7:0] data_out,
    output reg data_valid,
    input data_ready,
    // 错误标志
    output reg error_fixed, double_error
);
    reg [3:0] syndrome;
    reg parity_check;
    reg syndrome_nonzero;
    reg [11:0] code_word_reg;
    reg processing;
    
    // 握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_ready <= 1'b1;
            data_valid <= 1'b0;
            processing <= 1'b0;
            code_word_reg <= 12'b0;
        end else begin
            // 输入握手处理
            if (code_valid && code_ready) begin
                code_word_reg <= code_word;
                code_ready <= 1'b0;
                processing <= 1'b1;
            end
            
            // 处理完成，准备输出
            if (processing) begin
                data_valid <= 1'b1;
                processing <= 1'b0;
            end
            
            // 输出握手完成
            if (data_valid && data_ready) begin
                data_valid <= 1'b0;
                code_ready <= 1'b1;
            end
        end
    end
    
    // 解码逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome <= 4'b0;
            data_out <= 8'b0; 
            error_fixed <= 1'b0; 
            double_error <= 1'b0;
            parity_check <= 1'b0;
            syndrome_nonzero <= 1'b0;
        end else if (code_valid && code_ready) begin
            // 在接收新数据时开始处理
            // 奇偶校验位计算优化 - 通过提前计算部分位的XOR结果来减少关键路径延迟
            syndrome[0] <= code_word[0] ^ code_word[2] ^ code_word[4] ^ code_word[6] ^ code_word[8] ^ code_word[10];
            syndrome[1] <= code_word[1] ^ code_word[2] ^ code_word[5] ^ code_word[6] ^ code_word[9] ^ code_word[10];
            syndrome[2] <= code_word[3] ^ code_word[4] ^ code_word[5] ^ code_word[6];
            syndrome[3] <= code_word[7] ^ code_word[8] ^ code_word[9] ^ code_word[10];
            
            // 通过单独计算和存储中间结果来减少组合逻辑深度
            parity_check <= ^syndrome ^ code_word[11];
            syndrome_nonzero <= |syndrome;
            
            // 使用已计算的中间结果直接生成输出信号
            error_fixed <= syndrome_nonzero & ~parity_check;
            double_error <= syndrome_nonzero & parity_check;
            
            // 数据输出保持不变，但可以用连接操作代替多个选择
            data_out <= {code_word[10:7], code_word[6:4], code_word[2]};
        end
    end
endmodule