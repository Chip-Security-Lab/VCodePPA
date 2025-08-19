//SystemVerilog
module i2c_dual_addr_mode_slave(
    input wire clk, rst_n,
    input wire [6:0] addr_7bit,
    input wire [9:0] addr_10bit,
    input wire addr_mode, // 0=7bit, 1=10bit
    output reg [7:0] data_rx,
    output reg data_valid,
    inout wire sda, scl
);
    // 状态定义
    localparam IDLE = 3'b000;
    localparam ADDR_RECV = 3'b001;
    localparam DATA_RECV = 3'b010;
    localparam ADDR_10BIT = 3'b100;
    
    // 流水线阶段寄存器
    reg [2:0] state_stage1, state_stage2;
    reg [9:0] addr_buffer_stage1, addr_buffer_stage2;
    reg [7:0] data_buffer_stage1, data_buffer_stage2;
    reg [3:0] bit_count_stage1, bit_count_stage2;
    reg sda_out_stage1, sda_out_stage2;
    reg sda_oe_stage1, sda_oe_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg start_detected, stop_detected;
    reg scl_prev, sda_prev;
    
    // 带状进位加法器内部信号
    wire [9:0] addr_temp;
    wire [9:0] bit_pattern;
    wire [9:0] p_signals, g_signals;
    wire [10:0] carry;
    
    // SDA控制
    assign sda = sda_oe_stage2 ? 1'bz : sda_out_stage2;
    
    // 检测I2C起始和停止条件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_prev <= 1'b1;
            sda_prev <= 1'b1;
            start_detected <= 1'b0;
            stop_detected <= 1'b0;
        end else begin
            scl_prev <= scl;
            sda_prev <= sda;
            
            // 起始条件：SCL高，SDA从高到低
            start_detected <= (scl == 1'b1 && scl_prev == 1'b1 && sda_prev == 1'b1 && sda == 1'b0);
            
            // 停止条件：SCL高，SDA从低到高
            stop_detected <= (scl == 1'b1 && scl_prev == 1'b1 && sda_prev == 1'b0 && sda == 1'b1);
        end
    end
    
    // 生成传播和生成信号
    assign p_signals = addr_buffer_stage1 ^ bit_pattern;
    assign g_signals = addr_buffer_stage1 & bit_pattern;
    
    // 带状进位加法器 - 进位链
    assign carry[0] = 1'b0;
    assign carry[1] = g_signals[0] | (p_signals[0] & carry[0]);
    assign carry[2] = g_signals[1] | (p_signals[1] & g_signals[0]) | (p_signals[1] & p_signals[0] & carry[0]);
    assign carry[3] = g_signals[2] | (p_signals[2] & g_signals[1]) | (p_signals[2] & p_signals[1] & g_signals[0]) | 
                     (p_signals[2] & p_signals[1] & p_signals[0] & carry[0]);
    assign carry[4] = g_signals[3] | (p_signals[3] & g_signals[2]) | (p_signals[3] & p_signals[2] & g_signals[1]) |
                     (p_signals[3] & p_signals[2] & p_signals[1] & g_signals[0]) | 
                     (p_signals[3] & p_signals[2] & p_signals[1] & p_signals[0] & carry[0]);
    assign carry[5] = g_signals[4] | (p_signals[4] & carry[4]);
    assign carry[6] = g_signals[5] | (p_signals[5] & carry[5]);
    assign carry[7] = g_signals[6] | (p_signals[6] & carry[6]);
    assign carry[8] = g_signals[7] | (p_signals[7] & carry[7]);
    assign carry[9] = g_signals[8] | (p_signals[8] & carry[8]);
    assign carry[10] = g_signals[9] | (p_signals[9] & carry[9]);

    // 求和运算
    assign addr_temp = p_signals ^ carry[9:0];
    
    // 流水线第一级 - 状态和数据捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            addr_buffer_stage1 <= 10'b0;
            data_buffer_stage1 <= 8'b0;
            bit_count_stage1 <= 4'b0;
            sda_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (start_detected) begin
                state_stage1 <= ADDR_RECV;
                bit_count_stage1 <= 4'b0;
                addr_buffer_stage1 <= 10'b0;
            end else if (stop_detected) begin
                state_stage1 <= IDLE;
                valid_stage1 <= 1'b0;
            end else if (scl_prev == 1'b0 && scl == 1'b1) begin // SCL上升沿，采样数据
                case (state_stage1)
                    IDLE: begin
                        // 空闲状态，等待起始条件
                    end
                    
                    ADDR_RECV: begin
                        addr_buffer_stage1 <= {addr_buffer_stage1[8:0], sda};
                        bit_count_stage1 <= bit_count_stage1 + 4'b1;
                        
                        if (bit_count_stage1 == 4'd7) begin
                            // 下一个位是读/写位
                            sda_oe_stage1 <= 1'b0; // 准备ACK
                            sda_out_stage1 <= 1'b0;
                        end
                    end
                    
                    DATA_RECV: begin
                        data_buffer_stage1 <= {data_buffer_stage1[6:0], sda};
                        bit_count_stage1 <= bit_count_stage1 + 4'b1;
                        
                        if (bit_count_stage1 == 4'd7) begin
                            sda_oe_stage1 <= 1'b0; // 准备ACK
                            sda_out_stage1 <= 1'b0;
                        end
                    end
                    
                    ADDR_10BIT: begin
                        addr_buffer_stage1 <= {addr_buffer_stage1[8:0], sda};
                        bit_count_stage1 <= bit_count_stage1 + 4'b1;
                        
                        if (bit_count_stage1 == 4'd7) begin
                            sda_oe_stage1 <= 1'b0; // 准备ACK
                            sda_out_stage1 <= 1'b0;
                        end
                    end
                endcase
            end else if (scl_prev == 1'b1 && scl == 1'b0) begin // SCL下降沿，处理状态转换
                case (state_stage1)
                    ADDR_RECV: begin
                        if (bit_count_stage1 == 4'd8) begin
                            bit_count_stage1 <= 4'b0;
                            sda_oe_stage1 <= 1'b1; // 释放SDA
                            
                            if (!addr_mode && addr_temp[7:1] == addr_7bit) begin
                                state_stage1 <= DATA_RECV;
                            end else if (addr_mode && addr_temp[7:1] == 10'b1111000000) begin
                                state_stage1 <= ADDR_10BIT; // 10-bit地址首字节
                            end else begin
                                state_stage1 <= IDLE; // 地址不匹配
                            end
                        end
                    end
                    
                    DATA_RECV: begin
                        if (bit_count_stage1 == 4'd8) begin
                            bit_count_stage1 <= 4'b0;
                            sda_oe_stage1 <= 1'b1; // 释放SDA
                        end
                    end
                    
                    ADDR_10BIT: begin
                        if (bit_count_stage1 == 4'd8) begin
                            bit_count_stage1 <= 4'b0;
                            sda_oe_stage1 <= 1'b1; // 释放SDA
                            
                            // 检查第二字节是否匹配10位地址的低8位
                            if (addr_temp[7:0] == addr_10bit[7:0]) begin
                                state_stage1 <= DATA_RECV;
                            end else begin
                                state_stage1 <= IDLE; // 地址不匹配
                            end
                        end
                    end
                endcase
            end
        end
    end
    
    // 动态生成bit_pattern
    assign bit_pattern = (state_stage1 == ADDR_RECV) ? 10'b0000000001 :
                        (state_stage1 == DATA_RECV) ? 10'b0000000010 :
                        (state_stage1 == ADDR_10BIT) ? 10'b0000000100 : 10'b0;
    
    // 流水线第二级 - 数据处理和输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            addr_buffer_stage2 <= 10'b0;
            data_buffer_stage2 <= 8'b0;
            bit_count_stage2 <= 4'b0;
            sda_out_stage2 <= 1'b1;
            sda_oe_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
            data_rx <= 8'b0;
            data_valid <= 1'b0;
        end else begin
            // 从流水线第一级传递状态和控制信号
            state_stage2 <= state_stage1;
            addr_buffer_stage2 <= addr_temp;  // 使用CLA计算结果
            data_buffer_stage2 <= data_buffer_stage1;
            bit_count_stage2 <= bit_count_stage1;
            sda_out_stage2 <= sda_out_stage1;
            sda_oe_stage2 <= sda_oe_stage1;
            valid_stage2 <= valid_stage1;
            
            // 数据有效信号生成
            data_valid <= 1'b0; // 默认无效
            
            // 当数据接收完成时生成数据有效信号
            if (valid_stage2 && state_stage2 == DATA_RECV && bit_count_stage2 == 4'd8) begin
                data_rx <= data_buffer_stage2;
                data_valid <= 1'b1;
            end
        end
    end
endmodule