//SystemVerilog
module usb_packet_error_checker(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire packet_end,
    input wire [15:0] received_crc,
    output reg crc_error,
    output reg timeout_error,
    output reg bitstuff_error
);
    // 注册输入信号以减少输入到第一级寄存器的延迟
    reg [7:0] data_in_reg;
    reg data_valid_reg;
    reg packet_end_reg;
    reg [15:0] received_crc_reg;
    
    // 内部状态寄存器
    reg [15:0] calculated_crc;
    reg [7:0] timeout_counter;
    reg receiving;
    
    // 优化的CRC-16计算逻辑 - 将组合逻辑放在寄存器之后
    wire crc_feedback;
    wire [15:0] next_crc;
    
    // 超时检测阈值常量
    localparam TIMEOUT_THRESHOLD = 8'd200;
    
    // 输入寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'h0;
            data_valid_reg <= 1'b0;
            packet_end_reg <= 1'b0;
            received_crc_reg <= 16'h0;
        end else begin
            data_in_reg <= data_in;
            data_valid_reg <= data_valid;
            packet_end_reg <= packet_end;
            received_crc_reg <= received_crc;
        end
    end
    
    // 将CRC反馈逻辑放在寄存器阶段之后
    assign crc_feedback = calculated_crc[15];
    assign next_crc = {calculated_crc[14:0], 1'b0} ^ 
                     ({16{crc_feedback}} & 16'h8005);
    
    // 主处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calculated_crc <= 16'hFFFF;
            timeout_counter <= 8'd0;
            crc_error <= 1'b0;
            timeout_error <= 1'b0;
            bitstuff_error <= 1'b0;
            receiving <= 1'b0;
        end else begin
            // 默认情况下保持错误状态
            crc_error <= crc_error;
            timeout_error <= timeout_error;
            
            if (data_valid_reg) begin
                // 使用按位XOR优化CRC计算
                calculated_crc <= next_crc ^ {8'h00, data_in_reg};
                timeout_counter <= 8'd0;
                receiving <= 1'b1;
            end else if (receiving) begin
                // 计数器增加的优化逻辑
                if (timeout_counter < TIMEOUT_THRESHOLD) begin
                    timeout_counter <= timeout_counter + 1'b1;
                end else begin
                    timeout_error <= 1'b1;
                    receiving <= 1'b0;
                end
            end
            
            if (packet_end_reg) begin
                // 优化CRC比较逻辑
                crc_error <= (calculated_crc != received_crc_reg);
                calculated_crc <= 16'hFFFF;
                receiving <= 1'b0;
            end
        end
    end
endmodule