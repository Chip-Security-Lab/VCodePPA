//SystemVerilog
module EDAC_Stats_Decoder(
    input clk,
    input rst,  
    input valid_in,  
    input [31:0] encoded_data,
    output reg [27:0] decoded_data,
    output reg valid_out,  
    output reg [15:0] correct_count,
    output reg [15:0] error_count
);
    // 流水线寄存器定义
    reg [31:0] encoded_data_stage1;
    reg valid_stage1;
    reg [27:0] decoded_data_stage1;
    reg [3:0] error_pos_stage1;
    
    reg [27:0] decoded_data_stage2;
    reg [3:0] error_pos_stage2;
    reg valid_stage2;
    reg error_flag_stage2;
    
    // 汉明解码函数
    function [31:0] HammingDecode;
        input [31:0] encoded;
        reg [3:0] err_pos;
        reg [27:0] data;
        begin
            err_pos = 0;
            if (^encoded) err_pos = 1;
            data = encoded[31:4];
            HammingDecode = {data, err_pos};
        end
    endfunction

    // 第一级流水线 - 寄存数据输入
    always @(posedge clk) begin
        if (rst) begin
            encoded_data_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
            if (valid_in) begin
                encoded_data_stage1 <= encoded_data;
            end
        end
    end

    // 第一级流水线 - 执行解码操作
    always @(posedge clk) begin
        if (rst) begin
            decoded_data_stage1 <= 28'b0;
            error_pos_stage1 <= 4'b0;
        end
        else if (valid_in) begin
            {decoded_data_stage1, error_pos_stage1} <= HammingDecode(encoded_data);
        end
    end

    // 第二级流水线 - 传递解码数据
    always @(posedge clk) begin
        if (rst) begin
            decoded_data_stage2 <= 28'b0;
            error_pos_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                decoded_data_stage2 <= decoded_data_stage1;
                error_pos_stage2 <= error_pos_stage1;
            end
        end
    end
    
    // 第二级流水线 - 错误标记处理
    always @(posedge clk) begin
        if (rst) begin
            error_flag_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            error_flag_stage2 <= (error_pos_stage1 != 0);
        end
    end

    // 第三级流水线 - 输出控制
    always @(posedge clk) begin
        if (rst) begin
            decoded_data <= 28'b0;
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= valid_stage2;
            if (valid_stage2) begin
                decoded_data <= decoded_data_stage2;
            end
        end
    end
    
    // 第三级流水线 - 错误计数器更新
    always @(posedge clk) begin
        if (rst) begin
            error_count <= 16'b0;
        end
        else if (valid_stage2 && error_flag_stage2) begin
            error_count <= error_count + 1;
        end
    end
    
    // 第三级流水线 - 校正计数器更新
    always @(posedge clk) begin
        if (rst) begin
            correct_count <= 16'b0;
        end
        else if (valid_stage2 && error_flag_stage2 && (error_pos_stage2 <= 28)) begin
            correct_count <= correct_count + 1;
        end
    end
endmodule