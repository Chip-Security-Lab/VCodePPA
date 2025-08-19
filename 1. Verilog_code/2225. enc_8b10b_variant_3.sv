//SystemVerilog
module enc_8b10b #(parameter IMPLEMENT_TABLES = 1)
(
    input wire clk, reset_n, enable,
    input wire k_in,        // Control signal indicator
    input wire [7:0] data_in,
    input wire [9:0] encoded_in,
    output reg [9:0] encoded_out,
    output reg [7:0] data_out,
    output reg k_out,       // Decoded control indicator
    output reg disparity_err, code_err
);
    // 状态与中间信号
    reg disp_state;   // Running disparity (0=negative, 1=positive)
    
    // 编码与解码相关的寄存器
    reg [5:0] encoded_5b;
    reg [3:0] encoded_3b;
    
    // 组合逻辑中间变量
    reg [5:0] lut_5b6b_idx;
    reg [3:0] lut_3b4b_idx;
    reg [5:0] encoded_5b_next;
    reg [3:0] encoded_3b_next;
    reg disp_after_5b;
    
    // 中间信号用于解码
    reg [8:0] decoded_value;
    reg disparity_error_detected;
    reg code_error_detected;
    
    // 1. 时序逻辑 - 重置与状态更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            disp_state <= 1'b0;
        end else if (enable) begin
            disp_state <= compute_final_disparity(encoded_5b_next, encoded_3b_next, disp_state);
        end
    end
    
    // 2. 时序逻辑 - 编码输出寄存器更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            encoded_out <= 10'b0;
            encoded_5b <= 6'b0;
            encoded_3b <= 4'b0;
        end else if (enable) begin
            encoded_5b <= encoded_5b_next;
            encoded_3b <= encoded_3b_next;
            encoded_out <= {encoded_3b_next, encoded_5b_next};
        end
    end
    
    // 3. 时序逻辑 - 解码输出寄存器更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 8'b0;
            k_out <= 1'b0;
        end else if (enable) begin
            decoded_value = decode_symbol(encoded_in);
            data_out <= decoded_value[8:1];
            k_out <= decoded_value[0];
        end
    end
    
    // 4. 时序逻辑 - 错误检测输出更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            disparity_err <= 1'b0;
            code_err <= 1'b0;
        end else if (enable) begin
            disparity_err <= check_disparity_error(encoded_in, disp_state);
            code_err <= check_code_error(encoded_in);
        end
    end
    
    // 5. 组合逻辑 - 查找表索引计算
    always @(*) begin
        lut_5b6b_idx = {k_in, data_in[4:0]};
        lut_3b4b_idx = {k_in, disp_after_5b, data_in[7:5]};
    end
    
    // 6. 组合逻辑 - 5b/6b编码
    always @(*) begin
        case (lut_5b6b_idx)
            6'b000000: encoded_5b_next = disp_state ? 6'b011000 : 6'b100111;
            6'b000001: encoded_5b_next = disp_state ? 6'b100010 : 6'b011101;
            // Additional cases would be implemented here
            default:   encoded_5b_next = 6'b000000;
        endcase
        
        // 计算5b/6b编码后的视差
        disp_after_5b = calculate_5b_disparity(encoded_5b_next, disp_state);
    end
    
    // 7. 组合逻辑 - 3b/4b编码
    always @(*) begin
        case (lut_3b4b_idx)
            4'b0000: encoded_3b_next = disp_after_5b ? 4'b0111 : 4'b1000;
            4'b0001: encoded_3b_next = disp_after_5b ? 4'b1011 : 4'b0100;
            // Additional cases would be implemented here
            default: encoded_3b_next = 4'b0000;
        endcase
    end
    
    // 计算最终视差的函数
    function compute_final_disparity;
        input [5:0] enc_5b;
        input [3:0] enc_3b;
        input current_disp;
        reg disp_after_5b_local;
        begin
            disp_after_5b_local = calculate_5b_disparity(enc_5b, current_disp);
            compute_final_disparity = calculate_3b_disparity(enc_3b, disp_after_5b_local);
        end
    endfunction
    
    // 计算5b/6b编码后视差的函数
    function calculate_5b_disparity;
        input [5:0] enc_5b;
        input current_disp;
        reg [2:0] ones_count;
        begin
            ones_count = enc_5b[0] + enc_5b[1] + enc_5b[2] + enc_5b[3] + enc_5b[4] + enc_5b[5];
            
            if (ones_count > 3)
                calculate_5b_disparity = 1'b1;  // More ones than zeros
            else if (ones_count < 3)
                calculate_5b_disparity = 1'b0;  // More zeros than ones
            else
                calculate_5b_disparity = current_disp;  // Equal ones and zeros
        end
    endfunction
    
    // 计算3b/4b编码后视差的函数
    function calculate_3b_disparity;
        input [3:0] enc_3b;
        input current_disp;
        reg [2:0] ones_count;
        begin
            ones_count = enc_3b[0] + enc_3b[1] + enc_3b[2] + enc_3b[3];
            
            if (ones_count > 2)
                calculate_3b_disparity = 1'b1;  // More ones than zeros
            else if (ones_count < 2)
                calculate_3b_disparity = 1'b0;  // More zeros than ones
            else
                calculate_3b_disparity = current_disp;  // Equal ones and zeros
        end
    endfunction
    
    // 检查视差错误的函数
    function check_disparity_error;
        input [9:0] encoded;
        input disp;
        reg [3:0] count_ones;
        begin
            // Efficiently count ones using range comparison
            count_ones = encoded[0] + encoded[1] + encoded[2] + encoded[3] + encoded[4] +
                         encoded[5] + encoded[6] + encoded[7] + encoded[8] + encoded[9];
                         
            // Check for disparity error using optimized comparisons
            check_disparity_error = ((count_ones == 5) ? 1'b0 : 
                                     ((disp && count_ones > 5) || (!disp && count_ones < 5)));
        end
    endfunction
    
    // 检查代码错误的函数
    function check_code_error;
        input [9:0] encoded;
        begin
            // Simplified code error checking through pattern matching
            check_code_error = (encoded == 10'b0000000000) || (encoded == 10'b1111111111) ||
                               (encoded[5:0] == 6'b000000) || (encoded[5:0] == 6'b111111) ||
                               (encoded[9:6] == 4'b0000) || (encoded[9:6] == 4'b1111);
        end
    endfunction
    
    // 解码符号的函数
    function [8:0] decode_symbol;
        input [9:0] encoded;
        reg [7:0] data;
        reg k_indicator;
        begin
            // Efficient decoding would be implemented here
            // This is a placeholder
            data = 8'b0;
            k_indicator = 1'b0;
            decode_symbol = {data, k_indicator};
        end
    endfunction

endmodule