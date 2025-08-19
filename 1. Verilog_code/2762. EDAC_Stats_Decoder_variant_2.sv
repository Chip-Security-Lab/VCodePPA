//SystemVerilog
module EDAC_Stats_Decoder(
    input clk,
    input rst,  // 复位信号以支持流水线控制
    input [31:0] encoded_data,
    input req,  // 输入数据请求信号(原data_valid)
    output reg ack,  // 输出应答信号(原ready)
    output reg [27:0] decoded_data,
    output reg [15:0] correct_count,
    output reg [15:0] error_count
);
    // 流水线阶段1: 解码阶段的寄存器
    reg [31:0] encoded_data_stage1;
    reg [27:0] decoded_data_stage1;
    reg [3:0] error_pos_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 统计计算阶段的寄存器
    reg [27:0] decoded_data_stage2;
    reg [3:0] error_pos_stage2;
    reg error_flag_stage2;
    reg valid_stage2;
    
    // 握手状态机状态
    reg req_registered;
    
    // 汉明解码函数
    function [31:0] HammingDecode;
        input [31:0] encoded;
        reg [3:0] err_pos;
        reg [27:0] data;
        begin
            // 简化的汉明解码实现
            err_pos = 0;
            // 计算校验位
            if (^encoded) err_pos = 1;
            data = encoded[31:4]; // 简化示例，实际解码逻辑会更复杂
            HammingDecode = {data, err_pos};
        end
    endfunction
    
    // 请求-应答握手控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ack <= 1'b0;
            req_registered <= 1'b0;
        end else begin
            if (req && !req_registered) begin
                ack <= 1'b1;
                req_registered <= 1'b1;
            end else if (!req && req_registered) begin
                ack <= 1'b0;
                req_registered <= 1'b0;
            end else begin
                ack <= 1'b0;
            end
        end
    end
    
    // 流水线阶段1: 解码操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded_data_stage1 <= 32'b0;
            decoded_data_stage1 <= 28'b0;
            error_pos_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else if (req && !req_registered) begin
            encoded_data_stage1 <= encoded_data;
            {decoded_data_stage1, error_pos_stage1} <= HammingDecode(encoded_data);
            valid_stage1 <= 1'b1;
        end else if (!valid_stage2) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 流水线阶段2: 错误统计计算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            decoded_data_stage2 <= 28'b0;
            error_pos_stage2 <= 4'b0;
            error_flag_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            decoded_data_stage2 <= decoded_data_stage1;
            error_pos_stage2 <= error_pos_stage1;
            error_flag_stage2 <= (error_pos_stage1 != 0);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线输出阶段: 更新输出和计数器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            decoded_data <= 28'b0;
            correct_count <= 16'b0;
            error_count <= 16'b0;
        end else if (valid_stage2) begin
            decoded_data <= decoded_data_stage2;
            
            if (error_flag_stage2) begin
                error_count <= error_count + 1;
                if (error_pos_stage2 <= 28) begin
                    correct_count <= correct_count + 1;
                end
            end
        end
    end
endmodule