//SystemVerilog
`timescale 1ns / 1ps
module i2c_encoder (
    input clk, start, stop,
    input [7:0] addr, data,
    output reg sda, scl,
    output ack
);
    // 使用参数替代enum类型
    parameter IDLE = 3'd0, START = 3'd1, ADDR = 3'd2, DATA = 3'd3, STOP = 3'd4;
    
    reg [2:0] state, next_state;
    reg [3:0] bit_cnt, next_bit_cnt;
    reg ack_reg, next_ack_reg;
    reg next_sda, next_scl;
    
    // 高扇出信号的缓冲寄存器
    reg [3:0] bit_cnt_buf1, bit_cnt_buf2;
    reg scl_buf1, scl_buf2;
    
    // 状态寄存器更新
    always @(posedge clk) begin
        state <= next_state;
        bit_cnt <= next_bit_cnt;
        ack_reg <= next_ack_reg;
        sda <= next_sda;
        scl <= next_scl;
    end
    
    // 状态转换和控制逻辑
    always @(*) begin
        // 默认保持当前值
        next_state = state;
        next_bit_cnt = bit_cnt;
        next_ack_reg = ack_reg;
        next_sda = sda;
        next_scl = scl;
        
        if (start) begin
            next_state = START;
            next_bit_cnt = 4'h0;
            next_ack_reg = 1'b0;
        end else begin
            case(state)
                IDLE: begin
                    next_scl = 1'b1;
                    next_sda = 1'b1;
                    if (start) next_state = START;
                end
                START: begin 
                    next_scl = 1'b0; 
                    next_sda = 1'b0; 
                    next_state = ADDR; 
                end
                ADDR: begin
                    if (bit_cnt < 8) begin
                        next_sda = addr[7 - bit_cnt_buf1];
                        next_bit_cnt = bit_cnt + 1;
                        next_scl = ~scl_buf1;
                    end else begin
                        next_state = DATA;
                        next_bit_cnt = 4'h0;
                        next_ack_reg = 1'b1;
                    end
                end
                DATA: begin
                    if (bit_cnt < 8) begin
                        next_sda = data[7 - bit_cnt_buf2];
                        next_bit_cnt = bit_cnt + 1;
                        next_scl = ~scl_buf2;
                    end else if (stop) begin
                        next_state = STOP;
                        next_ack_reg = 1'b1;
                    end else begin
                        next_bit_cnt = 4'h0;
                        next_ack_reg = 1'b1;
                    end
                end
                STOP: begin
                    next_scl = 1'b1;
                    next_sda = 1'b1;
                    next_state = IDLE;
                end
                default: next_state = IDLE;
            endcase
        end
    end
    
    // 缓冲寄存器更新逻辑
    always @(posedge clk) begin
        bit_cnt_buf1 <= bit_cnt;
        bit_cnt_buf2 <= bit_cnt;
    end
    
    // SCL缓冲寄存器更新逻辑
    always @(posedge clk) begin
        scl_buf1 <= scl;
        scl_buf2 <= scl;
    end
    
    assign ack = ack_reg;
endmodule