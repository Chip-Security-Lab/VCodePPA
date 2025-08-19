//SystemVerilog
module lin_codec (
    input wire clk,
    input wire reset,
    input wire break_detect,
    input wire [7:0] pid,
    input wire data_valid_in,
    output wire data_ready_out,
    output reg tx,
    output wire tx_valid_out
);
    // 阶段定义 - 增加了更细粒度的状态
    localparam STAGE_IDLE = 3'd0;
    localparam STAGE_BREAK_SETUP = 3'd1;
    localparam STAGE_BREAK_ACTIVE = 3'd2;
    localparam STAGE_BREAK_END = 3'd3;
    localparam STAGE_DATA_SETUP = 3'd4;
    localparam STAGE_DATA_ACTIVE = 3'd5;
    localparam STAGE_DATA_END = 3'd6;
    localparam STAGE_DONE = 3'd7;
    
    // 流水线寄存器和控制信号 - 扩展位宽适应更多状态
    reg [2:0] current_stage;
    reg [2:0] next_stage;
    
    // 流水线阶段1寄存器 - 输入捕获
    reg [7:0] pid_stage1;
    reg break_detect_stage1;
    reg data_valid_stage1;
    
    // 流水线阶段2寄存器 - 数据准备
    reg [7:0] pid_stage2;
    reg break_detect_stage2;
    reg data_valid_stage2;
    
    // 流水线阶段3寄存器 - 帧构建
    reg [13:0] shift_reg_stage3;
    reg tx_active_stage3;
    
    // 流水线阶段4寄存器 - 发送控制
    reg [13:0] shift_reg_stage4;
    reg tx_valid_stage4;
    reg [3:0] bit_counter_stage4;
    
    // 输出赋值
    assign data_ready_out = (current_stage == STAGE_IDLE);
    assign tx_valid_out = tx_valid_stage4;
    
    // 阶段1: 输入捕获
    always @(posedge clk) begin
        if (reset) begin
            pid_stage1 <= 8'h0;
            break_detect_stage1 <= 1'b0;
            data_valid_stage1 <= 1'b0;
        end 
        else if (data_ready_out && data_valid_in) begin
            pid_stage1 <= pid;
            break_detect_stage1 <= break_detect;
            data_valid_stage1 <= 1'b1;
        end 
        else if (current_stage != STAGE_IDLE) begin
            data_valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2: 数据准备 - 新增流水线级
    always @(posedge clk) begin
        if (reset) begin
            pid_stage2 <= 8'h0;
            break_detect_stage2 <= 1'b0;
            data_valid_stage2 <= 1'b0;
        end 
        else begin
            pid_stage2 <= pid_stage1;
            break_detect_stage2 <= break_detect_stage1;
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // 阶段3: 帧构建 - 新增流水线级
    always @(posedge clk) begin
        if (reset) begin
            shift_reg_stage3 <= 14'h3FFF;
            tx_active_stage3 <= 1'b0;
        end 
        else begin
            case (current_stage)
                STAGE_IDLE: begin
                    shift_reg_stage3 <= 14'h3FFF;
                    tx_active_stage3 <= 1'b0;
                    if (data_valid_stage2 && !break_detect_stage2) begin
                        // 准备数据帧
                        shift_reg_stage3 <= {2'b00, pid_stage2, 4'h0};
                        tx_active_stage3 <= 1'b1;
                    end
                end
                
                STAGE_BREAK_SETUP: begin
                    tx_active_stage3 <= 1'b1;
                end
                
                STAGE_BREAK_END: begin
                    // Break结束后准备数据帧
                    shift_reg_stage3 <= {2'b00, pid_stage2, 4'h0};
                    tx_active_stage3 <= 1'b1;
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
    
    // 阶段4: 发送控制和输出驱动
    always @(posedge clk) begin
        if (reset) begin
            shift_reg_stage4 <= 14'h3FFF;
            tx_valid_stage4 <= 1'b0;
            bit_counter_stage4 <= 4'h0;
            tx <= 1'b1; // 空闲状态为1
        end 
        else begin
            case (current_stage)
                STAGE_IDLE: begin
                    tx <= 1'b1;
                    if (data_valid_stage2) begin
                        if (break_detect_stage2) begin
                            // 准备发送break
                            tx <= 1'b0;
                            tx_valid_stage4 <= 1'b1;
                            bit_counter_stage4 <= 4'h1;
                        end
                        else begin
                            // 准备发送数据起始位
                            tx <= 1'b0;
                            tx_valid_stage4 <= 1'b1;
                            bit_counter_stage4 <= 4'h0;
                            shift_reg_stage4 <= shift_reg_stage3;
                        end
                    end
                end
                
                STAGE_BREAK_SETUP, STAGE_BREAK_ACTIVE: begin
                    tx <= 1'b0;
                    if (current_stage == STAGE_BREAK_ACTIVE) begin
                        bit_counter_stage4 <= bit_counter_stage4 + 1'b1;
                    end
                end
                
                STAGE_BREAK_END: begin
                    tx <= 1'b1;
                    bit_counter_stage4 <= 4'h0;
                    shift_reg_stage4 <= shift_reg_stage3;
                end
                
                STAGE_DATA_SETUP: begin
                    // 起始位已在IDLE状态发送
                    shift_reg_stage4 <= shift_reg_stage3;
                    bit_counter_stage4 <= bit_counter_stage4 + 1'b1;
                end
                
                STAGE_DATA_ACTIVE: begin
                    tx <= shift_reg_stage4[13];
                    shift_reg_stage4 <= {shift_reg_stage4[12:0], 1'b1};
                    bit_counter_stage4 <= bit_counter_stage4 + 1'b1;
                end
                
                STAGE_DATA_END: begin
                    tx <= shift_reg_stage4[13];
                    shift_reg_stage4 <= {shift_reg_stage4[12:0], 1'b1};
                    tx_valid_stage4 <= 1'b0;
                end
                
                STAGE_DONE: begin
                    tx <= 1'b1;
                    tx_valid_stage4 <= 1'b0;
                end
            endcase
        end
    end
    
    // 状态转换逻辑 - 扩展为更细粒度的状态管理
    always @(*) begin
        next_stage = current_stage;
        
        case (current_stage)
            STAGE_IDLE: begin
                if (data_valid_stage2) begin
                    if (break_detect_stage2)
                        next_stage = STAGE_BREAK_SETUP;
                    else
                        next_stage = STAGE_DATA_SETUP;
                end
            end
            
            STAGE_BREAK_SETUP: begin
                next_stage = STAGE_BREAK_ACTIVE;
            end
            
            STAGE_BREAK_ACTIVE: begin
                if (bit_counter_stage4 == 4'd12)
                    next_stage = STAGE_BREAK_END;
            end
            
            STAGE_BREAK_END: begin
                next_stage = STAGE_DATA_SETUP;
            end
            
            STAGE_DATA_SETUP: begin
                next_stage = STAGE_DATA_ACTIVE;
            end
            
            STAGE_DATA_ACTIVE: begin
                if (bit_counter_stage4 == 4'd12)
                    next_stage = STAGE_DATA_END;
            end
            
            STAGE_DATA_END: begin
                next_stage = STAGE_DONE;
            end
            
            STAGE_DONE: begin
                next_stage = STAGE_IDLE;
            end
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk) begin
        if (reset)
            current_stage <= STAGE_IDLE;
        else
            current_stage <= next_stage;
    end
    
endmodule