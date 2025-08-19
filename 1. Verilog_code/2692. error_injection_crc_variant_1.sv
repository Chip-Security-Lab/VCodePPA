//SystemVerilog
module error_injection_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire inject_error,
    input wire [2:0] error_bit,
    output reg [7:0] crc_out
);
    // 优化常量参数定义
    localparam [7:0] POLY = 8'h07;
    
    // 优化错误注入逻辑
    wire [7:0] modified_data;
    wire crc_feedback_bit;
    wire [7:0] next_crc;
    
    // 错误注入优化：使用位选择而不是移位操作
    assign modified_data = data ^ {5'b0, inject_error && (error_bit == 3'd7), 
                                  inject_error && (error_bit == 3'd6),
                                  inject_error && (error_bit == 3'd5)};
    
    // LSB部分错误注入
    wire [4:0] lsb_error_mask;
    assign lsb_error_mask = {inject_error && (error_bit == 3'd4),
                            inject_error && (error_bit == 3'd3),
                            inject_error && (error_bit == 3'd2),
                            inject_error && (error_bit == 3'd1),
                            inject_error && (error_bit == 3'd0)};
    
    // 合并错误注入
    wire [7:0] data_with_error;
    assign data_with_error = {modified_data[7:5], modified_data[4:0] ^ lsb_error_mask};
    
    // 优化CRC反馈计算
    assign crc_feedback_bit = crc_out[7] ^ data_with_error[0];
    
    // 优化下一个CRC值计算，使用预计算的掩码
    wire [7:0] crc_shifted = {crc_out[6:0], 1'b0};
    assign next_crc = crc_shifted ^ (crc_feedback_bit ? POLY : 8'h00);
    
    // 寄存器更新逻辑优化：使用非阻塞赋值并添加复位默认值
    always @(posedge clk or posedge rst) begin
        if (rst) 
            crc_out <= 8'h00;
        else if (data_valid) 
            crc_out <= next_crc;
    end
endmodule