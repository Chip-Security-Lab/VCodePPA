//SystemVerilog
module EDAC_Stats_Decoder(
    input clk,
    input req,                  // Request signal (replaces valid)
    input [31:0] encoded_data,
    output reg ack,             // Acknowledge signal (replaces ready)
    output reg [27:0] decoded_data,
    output reg [15:0] correct_count,
    output reg [15:0] error_count
);
    // 内部信号定义
    reg [3:0] error_pos;
    reg [3:0] error_pos_next;
    reg error_flag;
    reg [27:0] decoded_data_next;
    reg req_r;                  // Registered request signal
    reg processing;             // Processing state flag
    
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

    // 解码逻辑 - 第一阶段
    always @(*) begin
        {decoded_data_next, error_pos_next} = HammingDecode(encoded_data);
    end

    // 请求-应答握手逻辑
    always @(posedge clk) begin
        req_r <= req;
        
        if (!processing && req && !req_r) begin
            // 新请求到达
            processing <= 1'b1;
            ack <= 1'b0;
        end
        else if (processing) begin
            // 处理完成，发送确认
            ack <= 1'b1;
            processing <= 1'b0;
        end
        else begin
            ack <= 1'b0;
        end
    end

    // 数据寄存 - 第二阶段
    always @(posedge clk) begin
        if (!processing && req && !req_r) begin
            decoded_data <= decoded_data_next;
            error_pos <= error_pos_next;
            error_flag <= (error_pos_next != 0);
        end
    end

    // 统计计数逻辑 - 第三阶段
    always @(posedge clk) begin
        if (!processing && req && !req_r && (error_pos_next != 0)) begin
            error_count <= error_count + 1;
            if(error_pos_next <= 28) begin
                correct_count <= correct_count + 1;
            end
        end
    end
endmodule