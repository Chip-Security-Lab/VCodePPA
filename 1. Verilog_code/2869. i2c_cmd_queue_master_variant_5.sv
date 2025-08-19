//SystemVerilog
//IEEE 1364-2005
module i2c_cmd_queue_master #(
    parameter QUEUE_DEPTH = 4
)(
    input clk, reset_n,
    input [7:0] cmd_data,
    input cmd_push, cmd_pop,
    output reg queue_full, queue_empty,
    output reg [7:0] rx_data,
    output reg transfer_done,
    inout scl, sda
);
    // 命令队列和指针
    reg [7:0] cmd_queue [0:QUEUE_DEPTH-1];
    reg [$clog2(QUEUE_DEPTH):0] head, tail;
    
    // 增加流水线深度：5级流水线
    reg [3:0] stage1_state, stage2_state, stage3_state, stage4_state, stage5_state;
    
    // 流水线控制信号
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid, stage5_valid;
    
    // I2C信号控制
    reg sda_out, scl_out, sda_en;
    
    // 状态定义
    parameter IDLE     = 4'b0000;
    parameter START    = 4'b0001;
    parameter ADDR_MSB = 4'b0010; // 地址高位部分
    parameter ADDR_LSB = 4'b0011; // 地址低位部分
    parameter ACK1     = 4'b0100;
    parameter TX_DATA_MSB = 4'b0101; // 数据高位部分
    parameter TX_DATA_LSB = 4'b0110; // 数据低位部分
    parameter ACK2     = 4'b0111;
    parameter STOP_PREP = 4'b1000; // 停止准备阶段
    parameter STOP     = 4'b1001;
    
    // 各流水线阶段的数据和控制寄存器
    reg [7:0] stage1_cmd, stage2_cmd, stage3_cmd, stage4_cmd, stage5_cmd;
    reg [3:0] stage1_bit_cnt, stage2_bit_cnt, stage3_bit_cnt, stage4_bit_cnt, stage5_bit_cnt;
    
    // I2C信号控制状态寄存器
    reg stage1_sda_out, stage1_scl_out, stage1_sda_en;
    reg stage2_sda_out, stage2_scl_out, stage2_sda_en;
    reg stage3_sda_out, stage3_scl_out, stage3_sda_en;
    reg stage4_sda_out, stage4_scl_out, stage4_sda_en;
    reg stage5_sda_out, stage5_scl_out, stage5_sda_en;
    
    // 队列状态信号
    assign queue_full = ((head + 1) % QUEUE_DEPTH) == tail;
    assign queue_empty = head == tail;
    
    // I2C总线驱动
    assign scl = scl_out ? 1'bz : 1'b0;
    assign sda = sda_en ? 1'bz : sda_out;
    
    // 第一阶段：队列管理和起始处理
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            head <= 0;
            tail <= 0;
            stage1_valid <= 1'b0;
            stage1_state <= IDLE;
            stage1_bit_cnt <= 4'b0000;
            stage1_sda_out <= 1'b1;
            stage1_scl_out <= 1'b1;
            stage1_sda_en <= 1'b1;
        end else begin
            // 队列管理逻辑
            if (cmd_push && !queue_full) begin
                cmd_queue[head] <= cmd_data;
                head <= (head + 1) % QUEUE_DEPTH;
            end
            
            if (cmd_pop && !queue_empty && stage1_state == IDLE && !stage1_valid) begin
                tail <= (tail + 1) % QUEUE_DEPTH;
            end
            
            // 阶段1状态机 - 队列处理和启动
            case (stage1_state)
                IDLE: begin
                    if (!queue_empty && !stage1_valid) begin
                        stage1_state <= START;
                        stage1_cmd <= cmd_queue[tail];
                        stage1_valid <= 1'b1;
                    end else begin
                        stage1_valid <= 1'b0;
                    end
                    stage1_sda_out <= 1'b1;
                    stage1_scl_out <= 1'b1;
                    stage1_sda_en <= 1'b1;
                    stage1_bit_cnt <= 4'b0000;
                end
                START: begin
                    stage1_sda_out <= 1'b0;
                    stage1_sda_en <= 1'b0;
                    stage1_state <= ADDR_MSB;
                end
                default: begin
                    stage1_state <= IDLE;
                    stage1_valid <= 1'b0;
                end
            endcase
        end
    end
    
    // 第二阶段：地址高位处理
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage2_valid <= 1'b0;
            stage2_state <= IDLE;
            stage2_cmd <= 8'h00;
            stage2_bit_cnt <= 4'b0000;
            stage2_sda_out <= 1'b1;
            stage2_scl_out <= 1'b1;
            stage2_sda_en <= 1'b1;
        end else begin
            // 数据从阶段1流向阶段2
            if (stage1_valid) begin
                stage2_valid <= stage1_valid;
                stage2_state <= stage1_state;
                stage2_cmd <= stage1_cmd;
                stage2_bit_cnt <= stage1_bit_cnt;
                stage2_sda_out <= stage1_sda_out;
                stage2_scl_out <= stage1_scl_out;
                stage2_sda_en <= stage1_sda_en;
            end else begin
                // 处理ADDR_MSB状态
                case (stage2_state)
                    ADDR_MSB: begin
                        if (stage2_bit_cnt < 4'b0011) begin // 处理高4位
                            stage2_bit_cnt <= stage2_bit_cnt + 1'b1;
                            stage2_sda_out <= stage2_cmd[7-stage2_bit_cnt];
                            stage2_sda_en <= 1'b0;
                        end else begin
                            stage2_state <= ADDR_LSB;
                            stage2_bit_cnt <= 4'b0000;
                        end
                    end
                    default: begin
                        // 保持状态不变或进入IDLE
                        if (!stage1_valid) begin
                            stage2_valid <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
    
    // 第三阶段：地址低位处理和确认
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage3_valid <= 1'b0;
            stage3_state <= IDLE;
            stage3_cmd <= 8'h00;
            stage3_bit_cnt <= 4'b0000;
            stage3_sda_out <= 1'b1;
            stage3_scl_out <= 1'b1;
            stage3_sda_en <= 1'b1;
        end else begin
            // 数据从阶段2流向阶段3
            if (stage2_valid) begin
                stage3_valid <= stage2_valid;
                stage3_state <= stage2_state;
                stage3_cmd <= stage2_cmd;
                stage3_bit_cnt <= stage2_bit_cnt;
                stage3_sda_out <= stage2_sda_out;
                stage3_scl_out <= stage2_scl_out;
                stage3_sda_en <= stage2_sda_en;
            end else begin
                // 处理ADDR_LSB和ACK1状态
                case (stage3_state)
                    ADDR_LSB: begin
                        if (stage3_bit_cnt < 4'b0011) begin // 处理低4位
                            stage3_bit_cnt <= stage3_bit_cnt + 1'b1;
                            stage3_sda_out <= stage3_cmd[3-stage3_bit_cnt];
                            stage3_sda_en <= 1'b0;
                        end else begin
                            stage3_state <= ACK1;
                            stage3_bit_cnt <= 4'b0000;
                            stage3_sda_en <= 1'b1; // 释放SDA总线等待从机ACK
                        end
                    end
                    ACK1: begin
                        stage3_state <= TX_DATA_MSB;
                    end
                    default: begin
                        // 保持状态不变或进入IDLE
                        if (!stage2_valid) begin
                            stage3_valid <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
    
    // 第四阶段：数据高位传输
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage4_valid <= 1'b0;
            stage4_state <= IDLE;
            stage4_cmd <= 8'h00;
            stage4_bit_cnt <= 4'b0000;
            stage4_sda_out <= 1'b1;
            stage4_scl_out <= 1'b1;
            stage4_sda_en <= 1'b1;
        end else begin
            // 数据从阶段3流向阶段4
            if (stage3_valid) begin
                stage4_valid <= stage3_valid;
                stage4_state <= stage3_state;
                stage4_cmd <= stage3_cmd;
                stage4_bit_cnt <= stage3_bit_cnt;
                stage4_sda_out <= stage3_sda_out;
                stage4_scl_out <= stage3_scl_out;
                stage4_sda_en <= stage3_sda_en;
            end else begin
                // 处理TX_DATA_MSB状态
                case (stage4_state)
                    TX_DATA_MSB: begin
                        if (stage4_bit_cnt < 4'b0011) begin // 处理高4位数据
                            stage4_bit_cnt <= stage4_bit_cnt + 1'b1;
                            stage4_sda_out <= stage4_cmd[7-stage4_bit_cnt];
                            stage4_sda_en <= 1'b0;
                        end else begin
                            stage4_state <= TX_DATA_LSB;
                            stage4_bit_cnt <= 4'b0000;
                        end
                    end
                    default: begin
                        // 保持状态不变或进入IDLE
                        if (!stage3_valid) begin
                            stage4_valid <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
    
    // 第五阶段：数据低位传输和完成
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage5_valid <= 1'b0;
            stage5_state <= IDLE;
            stage5_cmd <= 8'h00;
            stage5_bit_cnt <= 4'b0000;
            stage5_sda_out <= 1'b1;
            stage5_scl_out <= 1'b1;
            stage5_sda_en <= 1'b1;
            transfer_done <= 1'b0;
            rx_data <= 8'h00;
        end else begin
            // 数据从阶段4流向阶段5
            if (stage4_valid) begin
                stage5_valid <= stage4_valid;
                stage5_state <= stage4_state;
                stage5_cmd <= stage4_cmd;
                stage5_bit_cnt <= stage4_bit_cnt;
                stage5_sda_out <= stage4_sda_out;
                stage5_scl_out <= stage4_scl_out;
                stage5_sda_en <= stage4_sda_en;
                transfer_done <= 1'b0;
            end else begin
                // 处理TX_DATA_LSB、ACK2、STOP_PREP和STOP状态
                case (stage5_state)
                    TX_DATA_LSB: begin
                        if (stage5_bit_cnt < 4'b0011) begin // 处理低4位数据
                            stage5_bit_cnt <= stage5_bit_cnt + 1'b1;
                            stage5_sda_out <= stage5_cmd[3-stage5_bit_cnt];
                            stage5_sda_en <= 1'b0;
                        end else begin
                            stage5_state <= ACK2;
                            stage5_bit_cnt <= 4'b0000;
                            stage5_sda_en <= 1'b1; // 释放SDA总线等待从机ACK
                        end
                    end
                    ACK2: begin
                        stage5_state <= STOP_PREP;
                    end
                    STOP_PREP: begin
                        stage5_sda_out <= 1'b0;
                        stage5_sda_en <= 1'b0;
                        stage5_state <= STOP;
                    end
                    STOP: begin
                        stage5_sda_out <= 1'b1;
                        stage5_sda_en <= 1'b0;
                        stage5_scl_out <= 1'b1;
                        
                        // 传输完成，更新输出
                        transfer_done <= 1'b1;
                        rx_data <= stage5_cmd;
                        stage5_state <= IDLE;
                        stage5_valid <= 1'b0;
                    end
                    default: begin
                        // 保持状态不变或进入IDLE
                        if (!stage4_valid) begin
                            stage5_valid <= 1'b0;
                            transfer_done <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
    
    // I2C总线控制信号合并
    always @(*) begin
        if (stage5_valid) begin
            sda_out = stage5_sda_out;
            scl_out = stage5_scl_out;
            sda_en = stage5_sda_en;
        end else if (stage4_valid) begin
            sda_out = stage4_sda_out;
            scl_out = stage4_scl_out;
            sda_en = stage4_sda_en;
        end else if (stage3_valid) begin
            sda_out = stage3_sda_out;
            scl_out = stage3_scl_out;
            sda_en = stage3_sda_en;
        end else if (stage2_valid) begin
            sda_out = stage2_sda_out;
            scl_out = stage2_scl_out;
            sda_en = stage2_sda_en;
        end else if (stage1_valid) begin
            sda_out = stage1_sda_out;
            scl_out = stage1_scl_out;
            sda_en = stage1_sda_en;
        end else begin
            sda_out = 1'b1;
            scl_out = 1'b1;
            sda_en = 1'b1;
        end
    end
    
endmodule