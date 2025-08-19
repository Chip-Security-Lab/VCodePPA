//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005 Verilog标准
module i2c_bus_monitor(
    input wire        clk,            // 系统时钟
    input wire        rst_n,          // 低电平有效复位
    input wire        enable_monitor, // 监控使能
    output reg        bus_busy,       // 总线忙状态指示
    output reg [7:0]  last_addr,      // 最近检测到的地址
    output reg [7:0]  last_data,      // 最近检测到的数据
    output reg        error_detected, // 错误检测指示
    inout wire        sda,            // I2C数据线
    inout wire        scl             // I2C时钟线
);

    // 状态定义
    localparam IDLE      = 3'b000;
    localparam ADDR      = 3'b001;
    localparam RW_BIT    = 3'b010;
    localparam ACK_ADDR  = 3'b011;
    localparam DATA      = 3'b100;
    localparam ACK_DATA  = 3'b101;
    
    // 信号同步和边沿检测 - 第一级流水线
    reg sda_in_ff1, sda_in_ff2, sda_in_ff3;
    reg scl_in_ff1, scl_in_ff2, scl_in_ff3;
    
    // 第二级流水线 - 边沿检测寄存器
    reg sda_falling_stage2, sda_rising_stage2;
    reg scl_falling_stage2, scl_rising_stage2;
    reg sda_in_stage2, scl_in_stage2;
    
    // 第三级流水线 - 条件检测寄存器
    reg start_condition_stage3, stop_condition_stage3;
    reg sda_in_stage3, scl_in_stage3, scl_rising_stage3;
    reg enable_monitor_stage3;
    
    // 第四级流水线 - 状态跟踪和数据处理
    reg [2:0] monitor_state, next_state;
    reg [7:0] shift_reg, next_shift_reg;
    reg [3:0] bit_count, next_bit_count;
    reg bus_busy_stage4, bus_busy_next;
    
    // 第五级流水线 - 输出处理
    reg error_detected_next;
    reg [7:0] last_addr_next, last_data_next;
    
    // 输入同步 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_in_ff1 <= 1'b1;
            scl_in_ff1 <= 1'b1;
            sda_in_ff2 <= 1'b1;
            scl_in_ff2 <= 1'b1;
            sda_in_ff3 <= 1'b1;
            scl_in_ff3 <= 1'b1;
        end else begin
            // 三级寄存器同步
            sda_in_ff1 <= sda;
            scl_in_ff1 <= scl;
            sda_in_ff2 <= sda_in_ff1;
            scl_in_ff2 <= scl_in_ff1;
            sda_in_ff3 <= sda_in_ff2;
            scl_in_ff3 <= scl_in_ff2;
        end
    end
    
    // 第二级流水线 - 边沿检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_falling_stage2 <= 1'b0;
            sda_rising_stage2 <= 1'b0;
            scl_falling_stage2 <= 1'b0;
            scl_rising_stage2 <= 1'b0;
            sda_in_stage2 <= 1'b1;
            scl_in_stage2 <= 1'b1;
        end else begin
            sda_falling_stage2 <= sda_in_ff3 && !sda_in_ff2;
            sda_rising_stage2 <= !sda_in_ff3 && sda_in_ff2;
            scl_falling_stage2 <= scl_in_ff3 && !scl_in_ff2;
            scl_rising_stage2 <= !scl_in_ff3 && scl_in_ff2;
            sda_in_stage2 <= sda_in_ff2;
            scl_in_stage2 <= scl_in_ff2;
        end
    end
    
    // 第三级流水线 - I2C条件检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_condition_stage3 <= 1'b0;
            stop_condition_stage3 <= 1'b0;
            sda_in_stage3 <= 1'b1;
            scl_in_stage3 <= 1'b1;
            scl_rising_stage3 <= 1'b0;
            enable_monitor_stage3 <= 1'b0;
        end else begin
            start_condition_stage3 <= scl_in_stage2 && sda_falling_stage2;
            stop_condition_stage3 <= scl_in_stage2 && sda_rising_stage2;
            sda_in_stage3 <= sda_in_stage2;
            scl_in_stage3 <= scl_in_stage2;
            scl_rising_stage3 <= scl_rising_stage2;
            enable_monitor_stage3 <= enable_monitor;
        end
    end

    // 状态和控制逻辑 - 组合逻辑部分 (第四级流水线的组合部分)
    always @(*) begin
        // 默认保持当前值
        next_state = monitor_state;
        next_shift_reg = shift_reg;
        next_bit_count = bit_count;
        bus_busy_next = bus_busy_stage4;
        error_detected_next = error_detected;
        last_addr_next = last_addr;
        last_data_next = last_data;
        
        if (enable_monitor_stage3) begin
            // 检测START条件
            if (start_condition_stage3) begin
                next_state = ADDR;
                next_bit_count = 4'd7;
                bus_busy_next = 1'b1;
                next_shift_reg = 8'h00;
            end 
            // 检测STOP条件
            else if (stop_condition_stage3) begin
                next_state = IDLE;
                bus_busy_next = 1'b0;
            end
            // 采样数据路径
            else if (scl_rising_stage3 && bus_busy_stage4) begin
                case (monitor_state)
                    ADDR: begin
                        next_shift_reg = {shift_reg[6:0], sda_in_stage3};
                        if (bit_count == 4'd0) begin
                            next_state = RW_BIT;
                            last_addr_next = {shift_reg[6:0], sda_in_stage3};
                        end else begin
                            next_bit_count = bit_count - 4'd1;
                        end
                    end
                    
                    RW_BIT: begin
                        next_state = ACK_ADDR;
                    end
                    
                    ACK_ADDR: begin
                        if (!sda_in_stage3) begin // ACK
                            next_state = DATA;
                            next_bit_count = 4'd7;
                            next_shift_reg = 8'h00;
                        end else begin // NACK
                            error_detected_next = 1'b1;
                            next_state = IDLE;
                            bus_busy_next = 1'b0;
                        end
                    end
                    
                    DATA: begin
                        next_shift_reg = {shift_reg[6:0], sda_in_stage3};
                        if (bit_count == 4'd0) begin
                            next_state = ACK_DATA;
                            last_data_next = {shift_reg[6:0], sda_in_stage3};
                        end else begin
                            next_bit_count = bit_count - 4'd1;
                        end
                    end
                    
                    ACK_DATA: begin
                        if (!sda_in_stage3) begin // ACK
                            next_state = DATA;
                            next_bit_count = 4'd7;
                            next_shift_reg = 8'h00;
                        end else begin // NACK
                            next_state = IDLE;
                        end
                    end
                    
                    default: begin
                        next_state = IDLE;
                    end
                endcase
            end
        end
    end
    
    // 第四级流水线 - 状态和数据处理寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            monitor_state <= IDLE;
            shift_reg <= 8'h00;
            bit_count <= 4'h0;
            bus_busy_stage4 <= 1'b0;
        end else begin
            monitor_state <= next_state;
            shift_reg <= next_shift_reg;
            bit_count <= next_bit_count;
            bus_busy_stage4 <= bus_busy_next;
        end
    end
    
    // 第五级流水线 - 输出寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_busy <= 1'b0;
            error_detected <= 1'b0;
            last_addr <= 8'h00;
            last_data <= 8'h00;
        end else begin
            bus_busy <= bus_busy_stage4;
            error_detected <= error_detected_next;
            last_addr <= last_addr_next;
            last_data <= last_data_next;
        end
    end

endmodule