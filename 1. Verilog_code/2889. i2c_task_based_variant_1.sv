//SystemVerilog
module i2c_task_based #(
    parameter CMD_FIFO_DEPTH = 4
)(
    input clk,
    input rst_n,
    inout sda,
    inout scl,
    input cmd_valid,
    input [15:0] cmd_word,
    output reg cmd_ready
);
    // 基于任务的接口 - 将任务转换为可合成状态机
    localparam IDLE = 4'h0;
    localparam START = 4'h1;
    localparam ADDR = 4'h2;
    localparam DATA = 4'h3;
    localparam ACK = 4'h4;
    localparam STOP = 4'h5;
    localparam WAIT = 4'h6;
    
    reg [3:0] state, next_state;
    reg [7:0] addr_buffer, next_addr_buffer;
    reg [7:0] data_buffer, next_data_buffer;
    reg [2:0] bit_counter, next_bit_counter;
    reg sda_out, next_sda_out;
    reg scl_out, next_scl_out;
    reg sda_oe, next_sda_oe;
    reg scl_oe, next_scl_oe;
    reg next_cmd_ready;
    
    // I2C总线驱动 - 使用显式多路复用器
    assign sda = (sda_oe == 1'b1) ? sda_out : 1'bz;
    assign scl = (scl_oe == 1'b1) ? scl_out : 1'bz;

    // 使用跳跃进位加法器来处理bit_counter的增加
    // 定义进位生成和传播信号
    wire [2:0] g, p;
    wire [3:0] c;  // 包含初始进位
    
    // 生成和传播信号计算
    assign g[0] = bit_counter[0] & 1'b1;    // 与进位输入相与
    assign g[1] = bit_counter[1] & p[0];
    assign g[2] = bit_counter[2] & p[1];
    
    assign p[0] = bit_counter[0] | 1'b1;    // 与进位输入相或
    assign p[1] = bit_counter[1] | p[0];
    assign p[2] = bit_counter[2] | p[1];
    
    // 跳跃进位计算
    assign c[0] = 1'b1;  // 进位输入恒为1
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    
    // 增量计算函数
    function [2:0] increment_counter;
        input [2:0] counter;
        begin
            increment_counter[0] = counter[0] ^ c[0];
            increment_counter[1] = counter[1] ^ c[1];
            increment_counter[2] = counter[2] ^ c[2];
        end
    endfunction
    
    // 状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            addr_buffer <= 8'h0;
            data_buffer <= 8'h0;
            bit_counter <= 3'h0;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
            cmd_ready <= 1'b1;
        end else begin
            state <= next_state;
            addr_buffer <= next_addr_buffer;
            data_buffer <= next_data_buffer;
            bit_counter <= next_bit_counter;
            sda_out <= next_sda_out;
            scl_out <= next_scl_out;
            sda_oe <= next_sda_oe;
            scl_oe <= next_scl_oe;
            cmd_ready <= next_cmd_ready;
        end
    end
    
    // 下一状态和输出逻辑 - 使用显式多路复用器
    always @(*) begin
        // 默认值赋值
        next_state = state;
        next_addr_buffer = addr_buffer;
        next_data_buffer = data_buffer;
        next_bit_counter = bit_counter;
        next_sda_out = sda_out;
        next_scl_out = scl_out;
        next_sda_oe = sda_oe;
        next_scl_oe = scl_oe;
        next_cmd_ready = cmd_ready;
        
        case (state)
            IDLE: begin
                next_sda_out = 1'b1;
                next_scl_out = 1'b1;
                next_sda_oe = 1'b0;
                next_scl_oe = 1'b0;
                next_bit_counter = 3'h0;
                
                if (cmd_valid) begin
                    next_cmd_ready = 1'b0;
                    
                    case (cmd_word[15:12])
                        4'h1: begin
                            // 开始传输命令
                            next_addr_buffer = cmd_word[11:4];
                            next_data_buffer = cmd_word[7:0];
                            next_state = START;
                        end
                        default: begin
                            next_cmd_ready = 1'b1; // 未知命令
                        end
                    endcase
                end else begin
                    next_cmd_ready = 1'b1;
                end
            end
            
            START: begin
                // 发送起始条件
                next_sda_oe = 1'b1;
                next_scl_oe = 1'b1;
                next_scl_out = 1'b1;
                next_sda_out = 1'b0; // 发送起始位
                next_state = ADDR;
            end
            
            ADDR: begin
                // 发送地址
                next_sda_oe = 1'b1;
                next_scl_oe = 1'b1;
                
                // 时钟控制 - 使用显式多路复用器
                next_scl_out = ~scl_out;
                
                if (scl_out == 1'b0) begin
                    // SCL低电平时设置SDA - 使用显式多路复用器
                    next_sda_out = addr_buffer[7 - bit_counter];
                    
                    if (bit_counter == 3'h7) begin
                        next_bit_counter = 3'h0;
                        next_state = ACK;
                    end else begin
                        // 使用跳跃进位加法器替代普通加法
                        next_bit_counter = increment_counter(bit_counter);
                    end
                end
            end
            
            ACK: begin
                // 等待ACK
                next_scl_oe = 1'b1;
                
                // 时钟控制 - 使用显式多路复用器
                next_scl_out = ~scl_out;
                
                if (scl_out == 1'b0) begin
                    // 释放SDA总线以接收ACK
                    next_sda_oe = 1'b0;
                    next_state = DATA;
                end
            end
            
            DATA: begin
                // 发送数据
                next_sda_oe = 1'b1;
                next_scl_oe = 1'b1;
                
                // 时钟控制 - 使用显式多路复用器
                next_scl_out = ~scl_out;
                
                if (scl_out == 1'b0) begin
                    // SCL低电平时设置SDA - 使用显式多路复用器
                    next_sda_out = data_buffer[7 - bit_counter];
                    
                    if (bit_counter == 3'h7) begin
                        next_bit_counter = 3'h0;
                        next_state = STOP;
                    end else begin
                        // 使用跳跃进位加法器替代普通加法
                        next_bit_counter = increment_counter(bit_counter);
                    end
                end
            end
            
            STOP: begin
                // 发送停止条件
                next_sda_oe = 1'b1;
                next_scl_oe = 1'b1;
                next_scl_out = 1'b1;
                next_sda_out = 1'b0;
                next_state = WAIT;
            end
            
            WAIT: begin
                // 完成停止条件
                next_sda_out = 1'b1;
                next_state = IDLE;
                next_cmd_ready = 1'b1;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule