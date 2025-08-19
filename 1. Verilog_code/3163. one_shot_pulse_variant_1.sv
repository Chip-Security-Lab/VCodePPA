//SystemVerilog
module one_shot_pulse(
    input wire clk,
    input wire rst_n,
    input wire trigger,
    output wire pulse,
    
    // 流水线控制信号
    input wire valid_in,
    output wire valid_out,
    input wire ready_in,
    output wire ready_out
);
    // 流水线阶段定义
    localparam STAGE_DETECT = 0, STAGE_GENERATE = 1, STAGE_RESET = 2;
    
    // 流水线状态参数
    localparam IDLE = 2'b00, PULSE = 2'b01, WAIT = 2'b10;
    
    // 流水线寄存器和状态
    reg [1:0] state_stage1, state_stage2, state_stage3;
    reg trigger_stage1, trigger_stage2, trigger_stage3;
    reg pulse_stage1, pulse_stage2, pulse_stage3;
    
    // 流水线控制信号寄存器
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 输出信号
    assign pulse = pulse_stage3;
    assign valid_out = valid_stage3;
    assign ready_out = 1'b1;  // 流水线始终准备好接收新数据
    
    // 第一阶段控制逻辑 - 信号寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (ready_out) begin
            trigger_stage1 <= trigger;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第一阶段 - 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
        end else if (ready_out && valid_in) begin
            case (state_stage1)
                IDLE: state_stage1 <= trigger ? PULSE : IDLE;
                PULSE: state_stage1 <= WAIT;
                WAIT: state_stage1 <= !trigger ? IDLE : WAIT;
                default: state_stage1 <= IDLE;
            endcase
        end
    end
    
    // 第一阶段 - 脉冲生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_stage1 <= 1'b0;
        end else if (ready_out && valid_in) begin
            case (state_stage1)
                IDLE: pulse_stage1 <= trigger ? 1'b1 : 1'b0;
                default: pulse_stage1 <= 1'b0;
            endcase
        end
    end
    
    // 第二阶段 - 控制信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else if (ready_in) begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第二阶段 - 数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            trigger_stage2 <= 1'b0;
            pulse_stage2 <= 1'b0;
        end else if (ready_in) begin
            state_stage2 <= state_stage1;
            trigger_stage2 <= trigger_stage1;
            pulse_stage2 <= pulse_stage1;
        end
    end
    
    // 第三阶段 - 控制信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else if (ready_in) begin
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 第三阶段 - 数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            trigger_stage3 <= 1'b0;
            pulse_stage3 <= 1'b0;
        end else if (ready_in) begin
            state_stage3 <= state_stage2;
            trigger_stage3 <= trigger_stage2;
            pulse_stage3 <= pulse_stage2;
        end
    end
endmodule