//SystemVerilog
module PacketParser #(
    parameter CRC_POLY = 32'h04C11DB7
)(
    input clk, rst_n,
    input data_valid,
    input [7:0] data_in,
    output reg [31:0] crc_result,
    output reg packet_valid
);
    // 状态定义 - 使用约翰逊编码
    // 约翰逊编码格式：每个状态只有一位变化，形成环形移位模式
    localparam [2:0] STATE_IDLE = 3'b000,         // 000
                    STATE_HEADER_PROC = 3'b001,   // 001
                    STATE_PAYLOAD_PROC = 3'b011,  // 011
                    STATE_CRC_VALIDATE = 3'b111,  // 111
                    STATE_RESET = 3'b110;         // 110 (额外状态，用于回到IDLE形成环)
               
    // 主状态机寄存器 - 从2位扩展到3位以支持约翰逊编码
    reg [2:0] current_state, next_state;
    
    // 数据处理管道寄存器
    reg [7:0] data_in_reg;       // 输入数据缓存
    reg data_valid_reg;          // 数据有效标志缓存
    reg [31:0] crc_reg;          // CRC计算寄存器
    reg [31:0] crc_next;         // CRC计算中间结果
    reg [3:0] byte_counter;      // 报头字节计数器
    reg [3:0] byte_counter_next; // 下一周期字节计数器值
    
    // 管道控制信号
    reg header_complete;         // 报头处理完成标志
    reg payload_end_detected;    // 有效载荷结束标志
    reg crc_update_enable;       // CRC更新使能信号
    reg packet_validation_ready; // 数据包校验就绪信号

    // 优化的CRC计算函数
    function [31:0] calc_crc;
        input [7:0] data;
        input [31:0] crc;
        reg [31:0] result;
        integer i;
        begin
            result = crc;
            for (i=0; i<8; i=i+1) begin
                if ((data[7-i] ^ result[31]) == 1'b1)
                    result = (result << 1) ^ CRC_POLY;
                else
                    result = result << 1;
            end
            calc_crc = result;
        end
    endfunction

    // 第一级管道 - 输入数据寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'h0;
            data_valid_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            data_valid_reg <= data_valid;
        end
    end

    // 控制信号生成逻辑
    always @(*) begin
        // 默认值设置
        header_complete = (current_state == STATE_HEADER_PROC) && (byte_counter == 3) && data_valid_reg;
        payload_end_detected = (current_state == STATE_PAYLOAD_PROC) && (data_in_reg == 8'hAA) && data_valid_reg;
        crc_update_enable = (current_state == STATE_PAYLOAD_PROC) && data_valid_reg;
        packet_validation_ready = (current_state == STATE_CRC_VALIDATE);
        
        // 字节计数器下一个值计算
        if (current_state == STATE_HEADER_PROC && data_valid_reg) begin
            if (byte_counter == 3)
                byte_counter_next = 4'h0;
            else
                byte_counter_next = byte_counter + 1'b1;
        end else begin
            byte_counter_next = byte_counter;
        end
        
        // CRC中间结果计算
        if (crc_update_enable)
            crc_next = calc_crc(data_in_reg, crc_reg);
        else
            crc_next = crc_reg;
    end

    // 状态转换逻辑 - 使用约翰逊编码，每次转换只改变一位
    always @(*) begin
        next_state = current_state;
        
        case(current_state)
            STATE_IDLE: 
                if (data_in_reg == 8'h55 && data_valid_reg) 
                    next_state = STATE_HEADER_PROC; // 000 -> 001
                    
            STATE_HEADER_PROC: 
                if (header_complete) 
                    next_state = STATE_PAYLOAD_PROC; // 001 -> 011
                    
            STATE_PAYLOAD_PROC: 
                if (payload_end_detected) 
                    next_state = STATE_CRC_VALIDATE; // 011 -> 111
                    
            STATE_CRC_VALIDATE: 
                next_state = STATE_RESET; // 111 -> 110
                
            STATE_RESET:
                next_state = STATE_IDLE; // 110 -> 000
                
            default: 
                next_state = STATE_IDLE;
        endcase
    end

    // 第二级管道 - 主状态更新和数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            byte_counter <= 4'h0;
            crc_reg <= 32'hFFFFFFFF;
        end else begin
            current_state <= next_state;
            byte_counter <= byte_counter_next;
            crc_reg <= crc_next;
        end
    end

    // 第三级管道 - 输出生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_result <= 32'h0;
            packet_valid <= 1'b0;
        end else begin
            // 默认复位packet_valid
            packet_valid <= 1'b0;
            
            if (packet_validation_ready) begin
                crc_result <= crc_reg;
                packet_valid <= (crc_reg == 32'h0);
            end
        end
    end
endmodule