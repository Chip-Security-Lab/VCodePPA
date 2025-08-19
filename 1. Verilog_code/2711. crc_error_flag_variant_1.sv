//SystemVerilog
module crc_error_flag (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in, 
    input wire [15:0] expected_crc,
    output reg error_flag
);
    reg [15:0] current_crc;
    reg xor_result_r;
    reg [15:0] partial_next_crc_r;
    reg [15:0] next_crc_r;
    reg error_condition_r;
    
    // 第一级流水线：计算XOR的结果
    wire xor_result = current_crc[15] ^ data_in[15];
    
    // 第二级流水线：计算部分CRC
    wire [15:0] shifted_crc = {current_crc[14:0], 1'b0};
    wire [15:0] xor_value = xor_result_r ? 16'h1021 : 16'h0000;
    wire [15:0] partial_next_crc = shifted_crc ^ xor_value;
    
    // 第三级流水线：比较操作
    wire error_condition = (next_crc_r != expected_crc);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_crc <= 16'hFFFF;
            xor_result_r <= 1'b0;
            partial_next_crc_r <= 16'h0000;
            next_crc_r <= 16'hFFFF;
            error_condition_r <= 1'b0;
            error_flag <= 1'b0;
        end else begin
            // 第一级流水线寄存器
            xor_result_r <= xor_result;
            
            // 第二级流水线寄存器
            partial_next_crc_r <= partial_next_crc;
            
            // 第三级流水线寄存器
            next_crc_r <= partial_next_crc_r;
            current_crc <= next_crc_r;
            
            // 输出寄存器
            error_condition_r <= error_condition;
            error_flag <= error_condition_r;
        end
    end
endmodule