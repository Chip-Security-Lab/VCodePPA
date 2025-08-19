//SystemVerilog
module i2c_slave_dynaddr #(
    parameter FILTER_WIDTH = 3  // 输入滤波器参数
)(
    input clk,
    input rst_n,
    input scl,
    inout sda,
    output reg [7:0] data_out,
    output reg data_valid,
    input [7:0] data_in,
    input [6:0] slave_addr
);
    // 总线状态定义
    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam ADDR = 3'd2;
    localparam ACK_ADDR = 3'd3;
    localparam READ = 3'd4;
    localparam WRITE = 3'd5;
    localparam ACK_DATA = 3'd6;
    localparam STOP = 3'd7;

    // 流水线阶段1: 输入同步和滤波
    reg [FILTER_WIDTH-1:0] scl_filter_stage1, sda_filter_stage1;
    reg scl_sync_stage1, sda_sync_stage1;
    reg scl_filtered, sda_filtered;
    reg scl_prev, sda_prev;
    reg valid_stage1;

    // 流水线阶段2: 起始、停止和位计数
    reg start_detect_stage2, stop_detect_stage2;
    reg [2:0] bit_cnt_stage2;
    reg [2:0] state_stage2, next_state_stage2;
    reg valid_stage2;

    // 流水线阶段3: 数据移位和地址匹配
    reg [7:0] shift_reg_stage3;
    reg addr_match_stage3;
    reg rw_flag_stage3;
    reg valid_stage3;

    // 流水线阶段4: 数据处理和ACK/NACK生成
    reg sda_out_en_stage4;
    reg sda_out_val_stage4;
    reg [7:0] data_buf_stage4;
    
    // SDA三态控制
    assign sda = sda_out_en_stage4 ? sda_out_val_stage4 : 1'bz;

    // 流水线阶段1: 输入同步和滤波
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_filter_stage1 <= {FILTER_WIDTH{1'b0}};
            sda_filter_stage1 <= {FILTER_WIDTH{1'b0}};
            scl_sync_stage1 <= 1'b0;
            sda_sync_stage1 <= 1'b0;
            scl_filtered <= 1'b0;
            sda_filtered <= 1'b0;
            scl_prev <= 1'b0;
            sda_prev <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // 输入同步
            scl_sync_stage1 <= scl;
            sda_sync_stage1 <= sda;
            
            // 滤波处理
            scl_filter_stage1 <= {scl_filter_stage1[FILTER_WIDTH-2:0], scl_sync_stage1};
            sda_filter_stage1 <= {sda_filter_stage1[FILTER_WIDTH-2:0], sda_sync_stage1};
            
            // 滤波输出
            scl_filtered <= &scl_filter_stage1 ? 1'b1 : 
                          ~|scl_filter_stage1 ? 1'b0 : scl_filtered;
            sda_filtered <= &sda_filter_stage1 ? 1'b1 : 
                          ~|sda_filter_stage1 ? 1'b0 : sda_filtered;
            
            // 存储前一个值用于边沿检测
            scl_prev <= scl_filtered;
            sda_prev <= sda_filtered;
            
            valid_stage1 <= 1'b1; // 第一级流水线始终有效
        end
    end

    // 流水线阶段2: 起始、停止检测和状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_detect_stage2 <= 1'b0;
            stop_detect_stage2 <= 1'b0;
            bit_cnt_stage2 <= 3'b0;
            state_stage2 <= IDLE;
            next_state_stage2 <= IDLE;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // 检测START和STOP条件
            start_detect_stage2 <= scl_filtered && scl_prev && sda_prev && !sda_filtered;
            stop_detect_stage2 <= scl_filtered && scl_prev && !sda_prev && sda_filtered;
            
            // 状态机转换
            state_stage2 <= next_state_stage2;
            
            case (state_stage2)
                IDLE: begin
                    if (start_detect_stage2) begin
                        next_state_stage2 <= ADDR;
                        bit_cnt_stage2 <= 3'b0;
                    end
                end
                
                ADDR: begin
                    if (stop_detect_stage2) begin
                        next_state_stage2 <= IDLE;
                    end else if (start_detect_stage2) begin
                        next_state_stage2 <= ADDR;
                        bit_cnt_stage2 <= 3'b0;
                    end else if (scl_filtered && !scl_prev) begin // SCL上升沿
                        if (bit_cnt_stage2 == 3'b111) begin
                            next_state_stage2 <= ACK_ADDR;
                            bit_cnt_stage2 <= 3'b0;
                        end else begin
                            bit_cnt_stage2 <= bit_cnt_stage2 + 1'b1;
                        end
                    end
                end
                
                ACK_ADDR: begin
                    if (stop_detect_stage2) begin
                        next_state_stage2 <= IDLE;
                    end else if (start_detect_stage2) begin
                        next_state_stage2 <= ADDR;
                        bit_cnt_stage2 <= 3'b0;
                    end else if (!scl_filtered && scl_prev) begin // SCL下降沿
                        next_state_stage2 <= rw_flag_stage3 ? READ : WRITE;
                        bit_cnt_stage2 <= 3'b0;
                    end
                end
                
                READ: begin
                    if (stop_detect_stage2) begin
                        next_state_stage2 <= IDLE;
                    end else if (start_detect_stage2) begin
                        next_state_stage2 <= ADDR;
                        bit_cnt_stage2 <= 3'b0;
                    end else if (scl_filtered && !scl_prev) begin // SCL上升沿
                        if (bit_cnt_stage2 == 3'b111) begin
                            next_state_stage2 <= ACK_DATA;
                            bit_cnt_stage2 <= 3'b0;
                        end else begin
                            bit_cnt_stage2 <= bit_cnt_stage2 + 1'b1;
                        end
                    end
                end
                
                WRITE: begin
                    if (stop_detect_stage2) begin
                        next_state_stage2 <= IDLE;
                    end else if (start_detect_stage2) begin
                        next_state_stage2 <= ADDR;
                        bit_cnt_stage2 <= 3'b0;
                    end else if (scl_filtered && !scl_prev) begin // SCL上升沿
                        if (bit_cnt_stage2 == 3'b111) begin
                            next_state_stage2 <= ACK_DATA;
                            bit_cnt_stage2 <= 3'b0;
                        end else begin
                            bit_cnt_stage2 <= bit_cnt_stage2 + 1'b1;
                        end
                    end
                end
                
                ACK_DATA: begin
                    if (stop_detect_stage2) begin
                        next_state_stage2 <= IDLE;
                    end else if (start_detect_stage2) begin
                        next_state_stage2 <= ADDR;
                        bit_cnt_stage2 <= 3'b0;
                    end else if (!scl_filtered && scl_prev) begin // SCL下降沿
                        next_state_stage2 <= rw_flag_stage3 ? READ : WRITE;
                        bit_cnt_stage2 <= 3'b0;
                    end
                end
                
                default: next_state_stage2 <= IDLE;
            endcase
            
            valid_stage2 <= valid_stage1;
        end
    end

    // 流水线阶段3: 数据移位和地址匹配
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage3 <= 8'h00;
            addr_match_stage3 <= 1'b0;
            rw_flag_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            // 数据移位寄存器
            if (state_stage2 == ADDR || state_stage2 == READ || state_stage2 == WRITE) begin
                if (scl_filtered && !scl_prev) begin // SCL上升沿，采样数据
                    shift_reg_stage3 <= {shift_reg_stage3[6:0], sda_filtered};
                end
            end
            
            // 地址匹配逻辑
            if (state_stage2 == ADDR && bit_cnt_stage2 == 3'b111 && scl_filtered && !scl_prev) begin
                addr_match_stage3 <= (shift_reg_stage3[7:1] == slave_addr);
                rw_flag_stage3 <= sda_filtered; // 保存读/写标志位
            end
            
            valid_stage3 <= valid_stage2;
        end
    end

    // 流水线阶段4: 数据处理和输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out_en_stage4 <= 1'b0;
            sda_out_val_stage4 <= 1'b1;
            data_buf_stage4 <= 8'h00;
            data_out <= 8'h00;
            data_valid <= 1'b0;
        end else if (valid_stage3) begin
            // SDA输出控制
            case (state_stage2)
                ACK_ADDR: begin
                    if (scl_prev && !scl_filtered) begin // SCL下降沿
                        sda_out_en_stage4 <= 1'b1;
                        sda_out_val_stage4 <= addr_match_stage3 ? 1'b0 : 1'b1; // 地址匹配则ACK
                    end
                end
                
                READ: begin
                    if (state_stage2 != next_state_stage2 && next_state_stage2 == READ) begin
                        // 进入读取状态，准备输出数据
                        data_buf_stage4 <= data_in;
                    end
                    
                    if (!scl_filtered && scl_prev) begin // SCL下降沿，准备数据位
                        sda_out_en_stage4 <= 1'b1;
                        sda_out_val_stage4 <= data_buf_stage4[7 - bit_cnt_stage2];
                    end
                end
                
                WRITE: begin
                    sda_out_en_stage4 <= 1'b0; // 释放SDA线
                    
                    // 捕获完整字节后设置data_valid
                    if (bit_cnt_stage2 == 3'b111 && scl_filtered && !scl_prev) begin
                        data_out <= {shift_reg_stage3[6:0], sda_filtered};
                        data_valid <= 1'b1;
                    end else begin
                        data_valid <= 1'b0;
                    end
                end
                
                ACK_DATA: begin
                    if (scl_prev && !scl_filtered && !rw_flag_stage3) begin // 写操作的ACK
                        sda_out_en_stage4 <= 1'b1;
                        sda_out_val_stage4 <= 1'b0; // 发送ACK
                    end
                end
                
                default: begin
                    // 其他状态下，不驱动SDA
                    sda_out_en_stage4 <= 1'b0;
                    data_valid <= 1'b0;
                end
            endcase
            
            // 在STOP条件或地址不匹配时释放SDA
            if (stop_detect_stage2 || (state_stage2 == ACK_ADDR && !addr_match_stage3)) begin
                sda_out_en_stage4 <= 1'b0;
            end
        end
    end

endmodule