//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module eth_collision_detector (
    input wire clk,
    input wire rst_n,
    input wire transmitting,
    input wire receiving,
    input wire carrier_sense,
    output reg collision_detected,
    output reg jam_active,
    output reg [3:0] backoff_count,
    output reg [15:0] backoff_time
);
    // 中间寄存器 - 用于保存输入信号的寄存状态
    reg transmitting_r;
    reg receiving_r;
    reg carrier_sense_r;
    
    // 优化后的组合逻辑信号
    wire collision_condition;
    wire collision_new;
    wire reset_backoff;
    
    reg [3:0] collision_count;
    reg [7:0] jam_counter;
    
    localparam JAM_SIZE = 8'd32; // 32-byte jam pattern (16-bit time)
    localparam MAX_BACKOFF = 16'd1023; // 2^10 - 1
    
    // 输入信号寄存 - 使用非阻塞赋值确保时序正确
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transmitting_r <= 1'b0;
            receiving_r <= 1'b0;
            carrier_sense_r <= 1'b0;
        end else begin
            transmitting_r <= transmitting;
            receiving_r <= receiving;
            carrier_sense_r <= carrier_sense;
        end
    end
    
    // 优化的组合逻辑 - 使用简化表达式减少逻辑层次
    assign collision_condition = transmitting_r & (receiving_r | carrier_sense_r);
    assign collision_new = collision_condition & ~collision_detected;
    assign reset_backoff = ~transmitting_r & ~receiving_r & ~collision_detected & |collision_count;
    
    // 桶形移位器实现
    function [15:0] barrel_shifter;
        input [3:0] shift_amount;
        begin
            case (shift_amount)
                4'd0:  barrel_shifter = 16'd0;      // 2^0 - 1 = 0
                4'd1:  barrel_shifter = 16'd1;      // 2^1 - 1 = 1
                4'd2:  barrel_shifter = 16'd3;      // 2^2 - 1 = 3
                4'd3:  barrel_shifter = 16'd7;      // 2^3 - 1 = 7
                4'd4:  barrel_shifter = 16'd15;     // 2^4 - 1 = 15
                4'd5:  barrel_shifter = 16'd31;     // 2^5 - 1 = 31
                4'd6:  barrel_shifter = 16'd63;     // 2^6 - 1 = 63
                4'd7:  barrel_shifter = 16'd127;    // 2^7 - 1 = 127
                4'd8:  barrel_shifter = 16'd255;    // 2^8 - 1 = 255
                4'd9:  barrel_shifter = 16'd511;    // 2^9 - 1 = 511
                default: barrel_shifter = MAX_BACKOFF; // 2^10 - 1 = 1023
            endcase
        end
    endfunction
    
    // 主状态和计数处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_detected <= 1'b0;
            jam_active <= 1'b0;
            backoff_count <= 4'd0;
            backoff_time <= 16'd0;
            collision_count <= 4'd0;
            jam_counter <= 8'd0;
        end else begin
            // JAM 计数器逻辑 - 独立于碰撞检测处理
            if (jam_active) begin
                if (|jam_counter) // 非零检查更高效
                    jam_counter <= jam_counter - 1'b1;
                else
                    jam_active <= 1'b0;
            end
            
            // 碰撞检测和处理逻辑
            if (collision_condition) begin
                collision_detected <= 1'b1;
                
                if (collision_new) begin
                    // 启动JAM信号
                    jam_active <= 1'b1;
                    jam_counter <= JAM_SIZE;
                    
                    // 增加碰撞计数
                    collision_count <= collision_count + 1'b1;
                    backoff_count <= collision_count + 1'b1;
                    
                    // 使用桶形移位器实现退避时间计算
                    backoff_time <= barrel_shifter(collision_count);
                end
            end else if (~transmitting_r) begin
                // 只有在非传输状态才清除碰撞标志
                collision_detected <= 1'b0;
            end
            
            // 重置碰撞计数 - 独立条件处理提高时序性能
            if (reset_backoff) begin
                collision_count <= 4'd0;
            end
        end
    end
endmodule