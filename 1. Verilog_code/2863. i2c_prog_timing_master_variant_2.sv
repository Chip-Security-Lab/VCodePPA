//SystemVerilog
module i2c_prog_timing_master #(
    parameter DEFAULT_PRESCALER = 16'd100
)(
    input clk, reset_n,
    input [15:0] scl_prescaler,
    input [7:0] tx_data,
    input [6:0] slave_addr,
    input start_tx,
    output reg tx_done,
    inout scl, sda
);
    // 流水线阶段定义
    localparam IDLE        = 4'd0,
               START_BIT   = 4'd1,
               ADDR_PHASE  = 4'd2,
               ACK_ADDR    = 4'd3,
               DATA_PHASE  = 4'd4,
               ACK_DATA    = 4'd5,
               STOP_BIT    = 4'd6;
               
    // 时钟分频计数器
    reg [15:0] clk_div_count;
    reg [15:0] active_prescaler;
    
    // I2C信号控制
    reg scl_int, sda_int, scl_oe, sda_oe;
    
    // 流水线状态和控制信号
    reg [3:0] state_stage1;
    reg [3:0] state_stage2;
    reg [3:0] state_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线数据寄存器
    reg [7:0] tx_data_stage1, tx_data_stage2, tx_data_stage3;
    reg [6:0] slave_addr_stage1, slave_addr_stage2, slave_addr_stage3;
    
    // 位计数器和阶段计数器
    reg [3:0] bit_counter_stage2, bit_counter_stage3;
    
    // 流水线操作标志
    reg start_bit_done_stage2, addr_done_stage2, data_done_stage2;
    reg start_bit_done_stage3, addr_done_stage3, data_done_stage3;
    
    // SCL生成控制
    reg scl_toggle_enable;
    reg [1:0] scl_phase_counter;
    
    // I2C总线接口
    assign scl = (scl_oe == 1'b1) ? scl_int : 1'bz;
    assign sda = (sda_oe == 1'b1) ? sda_int : 1'bz;
    
    // 第一级流水线：预处理和prescaler设置
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            active_prescaler <= DEFAULT_PRESCALER;
            valid_stage1 <= 1'b0;
            state_stage1 <= IDLE;
            tx_data_stage1 <= 8'h00;
            slave_addr_stage1 <= 7'h00;
        end 
        else begin
            // 默认情况，保持有效性
            valid_stage1 <= valid_stage1;
            
            if (state_stage1 == IDLE && start_tx) begin
                // Prescaler设置
                case (scl_prescaler == 16'd0)
                    1'b1: active_prescaler <= DEFAULT_PRESCALER;
                    1'b0: active_prescaler <= scl_prescaler;
                endcase
                
                // 启动流水线
                valid_stage1 <= 1'b1;
                state_stage1 <= START_BIT;
                tx_data_stage1 <= tx_data;
                slave_addr_stage1 <= slave_addr;
            end
            else if (valid_stage2 && state_stage3 == STOP_BIT) begin
                // 完成传输，返回空闲状态
                valid_stage1 <= 1'b0;
                state_stage1 <= IDLE;
            end
        end
    end
    
    // 第二级流水线：时钟分频和I2C状态准备
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            clk_div_count <= 16'h0000;
            scl_toggle_enable <= 1'b0;
            valid_stage2 <= 1'b0;
            state_stage2 <= IDLE;
            tx_data_stage2 <= 8'h00;
            slave_addr_stage2 <= 7'h00;
            bit_counter_stage2 <= 4'h0;
            start_bit_done_stage2 <= 1'b0;
            addr_done_stage2 <= 1'b0;
            data_done_stage2 <= 1'b0;
        end
        else begin
            // 默认传递上一级信号
            valid_stage2 <= valid_stage1;
            state_stage2 <= state_stage1;
            tx_data_stage2 <= tx_data_stage1;
            slave_addr_stage2 <= slave_addr_stage1;
            
            // 时钟分频逻辑
            if (valid_stage1) begin
                if (clk_div_count >= active_prescaler - 1) begin
                    clk_div_count <= 16'h0000;
                    scl_toggle_enable <= 1'b1;
                    
                    // 位计数逻辑
                    if (state_stage2 == ADDR_PHASE) begin
                        if (bit_counter_stage2 == 4'd7) begin
                            bit_counter_stage2 <= 4'h0;
                            addr_done_stage2 <= 1'b1;
                        end else begin
                            bit_counter_stage2 <= bit_counter_stage2 + 1'b1;
                        end
                    end
                    else if (state_stage2 == DATA_PHASE) begin
                        if (bit_counter_stage2 == 4'd7) begin
                            bit_counter_stage2 <= 4'h0;
                            data_done_stage2 <= 1'b1;
                        end else begin
                            bit_counter_stage2 <= bit_counter_stage2 + 1'b1;
                        end
                    end
                    else if (state_stage2 == START_BIT) begin
                        start_bit_done_stage2 <= 1'b1;
                    end
                end else begin
                    clk_div_count <= clk_div_count + 1'b1;
                    scl_toggle_enable <= 1'b0;
                end
            end else begin
                clk_div_count <= 16'h0000;
                scl_toggle_enable <= 1'b0;
                bit_counter_stage2 <= 4'h0;
                start_bit_done_stage2 <= 1'b0;
                addr_done_stage2 <= 1'b0;
                data_done_stage2 <= 1'b0;
            end
        end
    end
    
    // 第三级流水线：I2C信号生成和控制
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            scl_int <= 1'b1;
            sda_int <= 1'b1;
            scl_oe <= 1'b1;
            sda_oe <= 1'b1;
            scl_phase_counter <= 2'b00;
            valid_stage3 <= 1'b0;
            state_stage3 <= IDLE;
            tx_data_stage3 <= 8'h00;
            slave_addr_stage3 <= 7'h00;
            bit_counter_stage3 <= 4'h0;
            start_bit_done_stage3 <= 1'b0;
            addr_done_stage3 <= 1'b0;
            data_done_stage3 <= 1'b0;
            tx_done <= 1'b0;
        end
        else begin
            // 默认传递上一级信号
            valid_stage3 <= valid_stage2;
            state_stage3 <= state_stage2;
            tx_data_stage3 <= tx_data_stage2;
            slave_addr_stage3 <= slave_addr_stage2;
            bit_counter_stage3 <= bit_counter_stage2;
            start_bit_done_stage3 <= start_bit_done_stage2;
            addr_done_stage3 <= addr_done_stage2;
            data_done_stage3 <= data_done_stage2;
            
            // I2C信号生成
            if (valid_stage2 && scl_toggle_enable) begin
                // SCL相位控制 (00->01->11->10->00)
                scl_phase_counter <= scl_phase_counter + 1'b1;
                
                case (scl_phase_counter)
                    2'b00: begin // SCL上升沿前
                        scl_int <= 1'b0;
                        case (state_stage3)
                            START_BIT: begin
                                sda_int <= 1'b1;
                                sda_oe <= 1'b1;
                            end
                            ADDR_PHASE: begin
                                sda_int <= slave_addr_stage3[6-bit_counter_stage3];
                                sda_oe <= 1'b1;
                            end
                            ACK_ADDR: begin
                                sda_oe <= 1'b0; // 释放总线以接收ACK
                            end
                            DATA_PHASE: begin
                                sda_int <= tx_data_stage3[7-bit_counter_stage3];
                                sda_oe <= 1'b1;
                            end
                            ACK_DATA: begin
                                sda_oe <= 1'b0; // 释放总线以接收ACK
                            end
                            STOP_BIT: begin
                                sda_int <= 1'b0;
                                sda_oe <= 1'b1;
                            end
                        endcase
                    end
                    2'b01: begin // SCL上升沿
                        scl_int <= 1'b1;
                    end
                    2'b10: begin // SCL下降沿前
                        scl_int <= 1'b1;
                        
                        // 状态转换逻辑
                        if (state_stage3 == START_BIT && start_bit_done_stage3) begin
                            state_stage3 <= ADDR_PHASE;
                            sda_int <= slave_addr_stage3[6]; // 准备发送地址的MSB
                        end
                        else if (state_stage3 == ADDR_PHASE && addr_done_stage3) begin
                            state_stage3 <= ACK_ADDR;
                        end
                        else if (state_stage3 == ACK_ADDR) begin
                            state_stage3 <= DATA_PHASE;
                            sda_int <= tx_data_stage3[7]; // 准备发送数据的MSB
                        end
                        else if (state_stage3 == DATA_PHASE && data_done_stage3) begin
                            state_stage3 <= ACK_DATA;
                        end
                        else if (state_stage3 == ACK_DATA) begin
                            state_stage3 <= STOP_BIT;
                            sda_int <= 1'b0; // 准备STOP条件
                        end
                        else if (state_stage3 == STOP_BIT) begin
                            tx_done <= 1'b1; // 传输完成
                        end
                    end
                    2'b11: begin // SCL下降沿
                        scl_int <= 1'b0;
                        
                        // 生成START和STOP条件
                        if (state_stage3 == START_BIT) begin
                            sda_int <= 1'b0; // START条件：SCL高时SDA从高到低
                        end
                        else if (state_stage3 == STOP_BIT) begin
                            sda_int <= 1'b1; // STOP条件：SCL高时SDA从低到高
                            tx_done <= 1'b0; // 重置完成标志，准备下一次传输
                        end
                    end
                endcase
            end
            else if (!valid_stage2) begin
                // 总线空闲状态
                scl_int <= 1'b1;
                sda_int <= 1'b1;
                scl_phase_counter <= 2'b00;
                tx_done <= 1'b0;
            end
        end
    end
endmodule