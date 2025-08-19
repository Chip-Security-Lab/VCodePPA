//SystemVerilog
module Reconfig_Hamming_Codec(
    input clk,
    input [1:0] config_mode,
    input [31:0] data_in,
    input req,        // 新增请求信号，替代valid
    output reg ack,   // 新增应答信号，替代ready
    output reg [31:0] data_out
);
    // 内部信号定义
    reg [6:0] hamming_7_4_out;
    reg [14:0] hamming_15_11_out;
    reg [30:0] hamming_31_26_out;
    reg [31:0] secded_out;
    reg req_reg;      // 寄存请求信号
    reg processing;   // 处理状态标志
    
    // 请求-应答握手逻辑
    always @(posedge clk) begin
        req_reg <= req;
        
        if (req && !req_reg && !processing) begin
            // 新请求到达，开始处理
            processing <= 1'b1;
            ack <= 1'b0;
        end else if (processing) begin
            // 完成处理，发送应答
            ack <= 1'b1;
            processing <= 1'b0;
        end else if (ack && !req) begin
            // 复位应答信号
            ack <= 1'b0;
        end
    end
    
    // (7,4)汉明码编码
    always @(posedge clk) begin
        if (req && !req_reg && !processing && config_mode == 2'b00) begin
            // 计算校验位
            hamming_7_4_out[3:0] <= data_in[3:0];                       // 原始数据
            hamming_7_4_out[4] <= ^data_in[3:0];                        // 奇偶校验
            hamming_7_4_out[5] <= data_in[3]^data_in[2];                // 校验位1
            hamming_7_4_out[6] <= data_in[3]^data_in[1];                // 校验位2
        end
    end
    
    // (15,11)汉明码编码
    always @(posedge clk) begin
        if (req && !req_reg && !processing && config_mode == 2'b01) begin
            // 复制原始数据
            hamming_15_11_out[10:0] <= data_in[10:0];
            
            // 生成校验位
            hamming_15_11_out[11] <= ^data_in[10:0];                    // 奇偶校验位
            hamming_15_11_out[12] <= data_in[10]^data_in[9]^data_in[6]^
                                     data_in[5]^data_in[3]^data_in[0];  // 校验位1
            hamming_15_11_out[13] <= data_in[10]^data_in[8]^data_in[7]^
                                     data_in[5]^data_in[4]^data_in[1];  // 校验位2
            hamming_15_11_out[14] <= data_in[9]^data_in[8]^data_in[7]^
                                     data_in[3]^data_in[2]^data_in[0];  // 校验位3
        end
    end
    
    // (31,26)汉明码编码
    always @(posedge clk) begin
        if (req && !req_reg && !processing && config_mode == 2'b10) begin
            // 复制原始数据
            hamming_31_26_out[25:0] <= data_in[25:0];
            
            // 生成校验位
            hamming_31_26_out[26] <= ^data_in[25:0];                     // 全局奇偶校验
            hamming_31_26_out[27] <= ^{data_in[25:20], data_in[15:10], 
                                      data_in[5:0]};                     // 分组校验1
            hamming_31_26_out[28] <= ^{data_in[25:16], data_in[10:1]};   // 分组校验2
            hamming_31_26_out[29] <= ^{data_in[25:21], data_in[15:11], 
                                      data_in[5:1]};                     // 分组校验3
            hamming_31_26_out[30] <= ^{data_in[20:16], data_in[10:6], 
                                      data_in[0]};                       // 分组校验4
        end
    end
    
    // SECDED (Single Error Correction, Double Error Detection)
    always @(posedge clk) begin
        if (req && !req_reg && !processing && config_mode == 2'b11) begin
            secded_out[30:0] <= data_in[30:0];                          // 原始数据
            secded_out[31] <= ^data_in[30:0];                           // 奇偶校验位
        end
    end
    
    // 最终输出多路复用器
    always @(posedge clk) begin
        if (req && !req_reg && !processing) begin
            case(config_mode)
                2'b00: begin // (7,4)码
                    data_out[6:0] <= hamming_7_4_out;
                    data_out[31:7] <= data_in[31:4];                        // 未编码部分直接传递
                end
                2'b01: begin // (15,11)码
                    data_out[14:0] <= hamming_15_11_out;
                    data_out[31:15] <= data_in[31:11];                      // 未编码部分直接传递
                end
                2'b10: begin // (31,26)码
                    data_out[30:0] <= hamming_31_26_out;
                    data_out[31] <= data_in[31:26] != 0;                    // 高位数据标志
                end
                2'b11: begin // SECDED
                    data_out[31:0] <= secded_out;                           // 完整的SECDED编码
                end
            endcase
        end
    end
endmodule