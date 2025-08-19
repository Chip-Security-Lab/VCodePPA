//SystemVerilog
module usb_async_receiver(
    input wire dm,
    input wire dp,
    input wire fast_clk,
    input wire reset,
    output wire [7:0] rx_data,
    output wire rx_valid,
    output wire rx_error
);
    // 内部状态定义
    localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
    
    // 流水线阶段定义
    localparam STAGE_INPUT = 2'b00, STAGE_PROCESS = 2'b01, STAGE_OUTPUT = 2'b10;
    
    // 寄存器定义 - 增加流水线级别
    reg [1:0] state_stage1, state_stage2, state_stage3;
    reg [2:0] bit_count_stage1, bit_count_stage2, bit_count_stage3;
    reg [7:0] shift_reg_stage1, shift_reg_stage2, shift_reg_stage3;
    reg [7:0] rx_data_reg_stage1, rx_data_reg_stage2, rx_data_reg_stage3;
    reg rx_valid_reg_stage1, rx_valid_reg_stage2, rx_valid_reg_stage3;
    reg rx_error_reg_stage1, rx_error_reg_stage2, rx_error_reg_stage3;
    
    // 输入流水线寄存器
    reg dm_stage1, dp_stage1;
    
    // 中间流水线寄存器
    reg [1:0] next_state_stage1, next_state_stage2;
    reg [2:0] next_bit_count_stage1, next_bit_count_stage2;
    reg [7:0] next_shift_reg_stage1, next_shift_reg_stage2;
    reg [7:0] next_rx_data_stage1, next_rx_data_stage2;
    reg next_rx_valid_stage1, next_rx_valid_stage2;
    reg next_rx_error_stage1, next_rx_error_stage2;
    
    // 输出连接
    assign rx_data = rx_data_reg_stage3;
    assign rx_valid = rx_valid_reg_stage3;
    assign rx_error = rx_error_reg_stage3;
    
    // 流水线阶段1 - 输入采样
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            dm_stage1 <= 1'b0;
            dp_stage1 <= 1'b0;
            state_stage1 <= IDLE;
            bit_count_stage1 <= 3'h0;
            shift_reg_stage1 <= 8'h0;
            rx_data_reg_stage1 <= 8'h0;
            rx_valid_reg_stage1 <= 1'b0;
            rx_error_reg_stage1 <= 1'b0;
        end else begin
            dm_stage1 <= dm;
            dp_stage1 <= dp;
            state_stage1 <= state_stage3;
            bit_count_stage1 <= bit_count_stage3;
            shift_reg_stage1 <= shift_reg_stage3;
            rx_data_reg_stage1 <= rx_data_reg_stage3;
            rx_valid_reg_stage1 <= rx_valid_reg_stage3;
            rx_error_reg_stage1 <= rx_error_reg_stage3;
        end
    end
    
    // 流水线阶段2 - 状态计算逻辑
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            next_state_stage1 <= IDLE;
            next_bit_count_stage1 <= 3'h0;
            next_shift_reg_stage1 <= 8'h0;
            next_rx_data_stage1 <= 8'h0;
            next_rx_valid_stage1 <= 1'b0;
            next_rx_error_stage1 <= 1'b0;
            state_stage2 <= IDLE;
            bit_count_stage2 <= 3'h0;
            shift_reg_stage2 <= 8'h0;
            rx_data_reg_stage2 <= 8'h0;
            rx_valid_reg_stage2 <= 1'b0;
            rx_error_reg_stage2 <= 1'b0;
        end else begin
            // 状态计算 - 第一阶段
            state_stage2 <= state_stage1;
            bit_count_stage2 <= bit_count_stage1;
            shift_reg_stage2 <= shift_reg_stage1;
            rx_data_reg_stage2 <= rx_data_reg_stage1;
            rx_valid_reg_stage2 <= rx_valid_reg_stage1;
            rx_error_reg_stage2 <= rx_error_reg_stage1;
            
            // 状态转换逻辑 - 初始计算阶段
            case (state_stage1)
                IDLE: begin
                    next_state_stage1 <= (dp_stage1 && !dm_stage1) ? SYNC : IDLE;
                    next_bit_count_stage1 <= 3'h0;
                    next_rx_valid_stage1 <= 1'b0;
                    next_shift_reg_stage1 <= shift_reg_stage1;
                    next_rx_data_stage1 <= rx_data_reg_stage1;
                    next_rx_error_stage1 <= rx_error_reg_stage1;
                end
                
                SYNC: begin
                    next_bit_count_stage1 <= bit_count_stage1 + 1'b1;
                    next_state_stage1 <= (bit_count_stage1 == 3'h7) ? DATA : SYNC;
                    next_rx_valid_stage1 <= 1'b0;
                    next_shift_reg_stage1 <= shift_reg_stage1;
                    next_rx_data_stage1 <= rx_data_reg_stage1;
                    next_rx_error_stage1 <= rx_error_reg_stage1;
                end
                
                DATA: begin
                    next_bit_count_stage1 <= bit_count_stage1 + 1'b1;
                    next_shift_reg_stage1 <= {dp_stage1, shift_reg_stage1[7:1]};
                    next_state_stage1 <= (bit_count_stage1 == 3'h7) ? EOP : DATA;
                    next_rx_data_stage1 <= (bit_count_stage1 == 3'h7) ? 
                                          {dp_stage1, shift_reg_stage1[7:1]} : rx_data_reg_stage1;
                    next_rx_valid_stage1 <= 1'b0;
                    next_rx_error_stage1 <= rx_error_reg_stage1;
                end
                
                EOP: begin
                    next_rx_valid_stage1 <= 1'b1;
                    next_bit_count_stage1 <= 3'h0;
                    next_state_stage1 <= (!dp_stage1 && !dm_stage1) ? IDLE : EOP;
                    next_shift_reg_stage1 <= shift_reg_stage1;
                    next_rx_data_stage1 <= rx_data_reg_stage1;
                    next_rx_error_stage1 <= rx_error_reg_stage1;
                end
                
                default: begin
                    next_state_stage1 <= IDLE;
                    next_rx_valid_stage1 <= 1'b0;
                    next_bit_count_stage1 <= 3'h0;
                    next_shift_reg_stage1 <= 8'h0;
                    next_rx_data_stage1 <= 8'h0;
                    next_rx_error_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // 流水线阶段2.5 - 数据处理逻辑进一步细分
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            next_state_stage2 <= IDLE;
            next_bit_count_stage2 <= 3'h0;
            next_shift_reg_stage2 <= 8'h0;
            next_rx_data_stage2 <= 8'h0;
            next_rx_valid_stage2 <= 1'b0;
            next_rx_error_stage2 <= 1'b0;
        end else begin
            // 进一步处理阶段 - 增加计算复杂度的拆分
            next_state_stage2 <= next_state_stage1;
            next_bit_count_stage2 <= next_bit_count_stage1;
            next_shift_reg_stage2 <= next_shift_reg_stage1;
            next_rx_data_stage2 <= next_rx_data_stage1;
            next_rx_valid_stage2 <= next_rx_valid_stage1;
            next_rx_error_stage2 <= next_rx_error_stage1;
            
            // 这里可以添加额外的数据处理逻辑，如CRC校验或协议解析
            // 将计算复杂度分布到多个流水线阶段
            if (state_stage2 == DATA) begin
                // 数据有效性验证逻辑
                if (bit_count_stage2 == 3'h7) begin
                    // 检查SYNC字段是否符合要求
                    if (shift_reg_stage2 != 8'hF0) begin
                        next_rx_error_stage2 <= 1'b1;
                    end
                end
            end
        end
    end
    
    // 流水线阶段3 - 输出更新
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            state_stage3 <= IDLE;
            bit_count_stage3 <= 3'h0;
            shift_reg_stage3 <= 8'h0;
            rx_data_reg_stage3 <= 8'h0;
            rx_valid_reg_stage3 <= 1'b0;
            rx_error_reg_stage3 <= 1'b0;
        end else begin
            state_stage3 <= next_state_stage2;
            bit_count_stage3 <= next_bit_count_stage2;
            shift_reg_stage3 <= next_shift_reg_stage2;
            rx_data_reg_stage3 <= next_rx_data_stage2;
            rx_valid_reg_stage3 <= next_rx_valid_stage2;
            rx_error_reg_stage3 <= next_rx_error_stage2;
        end
    end
endmodule