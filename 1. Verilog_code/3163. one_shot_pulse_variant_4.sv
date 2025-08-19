//SystemVerilog
module one_shot_pulse(
    input clk,
    input rst_n,
    input trigger,
    output reg pulse
);
    // 状态定义
    parameter IDLE = 3'b000, 
              PRE_PULSE = 3'b001,
              PULSE = 3'b010, 
              POST_PULSE = 3'b011,
              WAIT = 3'b100,
              PRE_IDLE = 3'b101;
    
    // 状态寄存器
    reg [2:0] state_stage1;
    reg [2:0] state_stage2;
    reg trigger_stage1;
    reg trigger_stage2;
    
    // 为高扇出信号添加缓冲寄存器
    reg [2:0] IDLE_buf1, IDLE_buf2;  // IDLE信号的缓冲
    reg rst_n_buf1, rst_n_buf2;      // 复位信号缓冲
    
    // 复位信号的缓冲寄存器
    always @(posedge clk) begin
        rst_n_buf1 <= rst_n;
        rst_n_buf2 <= rst_n_buf1;
    end
    
    // 高扇出常量的缓冲寄存器
    always @(posedge clk) begin
        IDLE_buf1 <= IDLE;
        IDLE_buf2 <= IDLE_buf1;
    end
    
    // 第一级流水线 - 输入采样和状态预处理
    always @(posedge clk or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            trigger_stage1 <= 1'b0;
            state_stage1 <= IDLE_buf1;
        end else begin
            trigger_stage1 <= trigger;
            
            case (state_stage1)
                IDLE_buf1: 
                    if (trigger_stage1)
                        state_stage1 <= PRE_PULSE;
                PRE_PULSE:
                    state_stage1 <= PULSE;
                PULSE:
                    state_stage1 <= POST_PULSE;
                POST_PULSE:
                    state_stage1 <= WAIT;
                WAIT:
                    if (!trigger_stage1)
                        state_stage1 <= PRE_IDLE;
                PRE_IDLE:
                    state_stage1 <= IDLE_buf1;
                default:
                    state_stage1 <= IDLE_buf1;
            endcase
        end
    end
    
    // 第二级流水线 - 状态处理和输出生成
    always @(posedge clk or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            trigger_stage2 <= 1'b0;
            state_stage2 <= IDLE_buf2;
            pulse <= 1'b0;
        end else begin
            trigger_stage2 <= trigger_stage1;
            state_stage2 <= state_stage1;
            
            case (state_stage2)
                PRE_PULSE:
                    pulse <= 1'b1;
                PULSE:
                    pulse <= 1'b1;
                POST_PULSE:
                    pulse <= 1'b0;
                default:
                    pulse <= 1'b0;
            endcase
        end
    end
endmodule