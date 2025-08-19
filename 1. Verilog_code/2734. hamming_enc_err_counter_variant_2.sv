//SystemVerilog
module hamming_enc_err_counter(
    input clk, rst, en,
    input [3:0] data_in,
    input error_inject,
    output reg [6:0] encoded,
    output reg [7:0] error_count
);
    // 定义流水线寄存器
    reg [3:0] data_stage1;
    reg error_inject_stage1;
    reg valid_stage1;
    
    // 中间计算结果寄存器
    reg parity1_stage1, parity2_stage1, parity3_stage1;
    reg [6:0] encoded_stage2;
    reg error_injected_stage2;
    
    // 第一级流水线 - 数据缓存和基本计算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 4'b0;
            error_inject_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            parity1_stage1 <= 1'b0;
            parity2_stage1 <= 1'b0;
            parity3_stage1 <= 1'b0;
        end else if (en) begin
            data_stage1 <= data_in;
            error_inject_stage1 <= error_inject;
            valid_stage1 <= 1'b1;
            
            // 预计算奇偶校验位
            parity1_stage1 <= data_in[0] ^ data_in[1] ^ data_in[3];
            parity2_stage1 <= data_in[0] ^ data_in[2] ^ data_in[3];
            parity3_stage1 <= data_in[1] ^ data_in[2] ^ data_in[3];
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线 - 编码和错误注入
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded_stage2 <= 7'b0;
            error_injected_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // 根据奇偶校验位和数据构建编码后的输出
            encoded_stage2[0] <= error_inject_stage1 ? ~parity1_stage1 : parity1_stage1;
            encoded_stage2[1] <= parity2_stage1;
            encoded_stage2[2] <= data_stage1[0];
            encoded_stage2[3] <= parity3_stage1;
            encoded_stage2[4] <= data_stage1[1];
            encoded_stage2[5] <= data_stage1[2];
            encoded_stage2[6] <= data_stage1[3];
            
            error_injected_stage2 <= error_inject_stage1;
        end
    end
    
    // 第三级流水线 - 输出和错误计数
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            error_count <= 8'b0;
        end else begin
            encoded <= encoded_stage2;
            
            if (error_injected_stage2) begin
                error_count <= error_count + 1;
            end
        end
    end
endmodule