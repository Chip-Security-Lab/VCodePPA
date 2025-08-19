//SystemVerilog
module fsm_controlled_shifter (
    input clk,
    input rst,
    input start,
    input [31:0] data,
    input [4:0] total_shift,
    output reg done,
    output reg [31:0] result,
    // 流水线控制信号
    output reg ready_for_next,
    input valid_in
);

// 用参数定义状态常量
localparam IDLE = 2'b00;
localparam LOAD = 2'b01;
localparam SHIFT = 2'b10;
localparam FINISH = 2'b11;

// 状态和控制寄存器
reg [1:0] state;
reg [4:0] cnt;

// 流水线寄存器
reg [31:0] data_stage1, data_stage2;
reg [4:0] total_shift_stage1, total_shift_stage2;
reg valid_stage1, valid_stage2, valid_stage3;
reg [31:0] partial_result;

// 高扇出信号缓冲寄存器
reg [1:0] idle_buffer1, idle_buffer2;
reg idle_cmp1, idle_cmp2, idle_cmp3, idle_cmp4;
reg shift_done_flag;
reg cnt_zero_flag1, cnt_zero_flag2;

// 状态转换和控制信号生成
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // 初始化缓冲寄存器
        idle_buffer1 <= IDLE;
        idle_buffer2 <= IDLE;
        idle_cmp1 <= 1'b1;
        idle_cmp2 <= 1'b1;
        idle_cmp3 <= 1'b1;
        idle_cmp4 <= 1'b1;
        cnt_zero_flag1 <= 1'b0;
        cnt_zero_flag2 <= 1'b0;
        shift_done_flag <= 1'b0;
    end else begin
        // 更新IDLE状态缓冲
        idle_buffer1 <= IDLE;
        idle_buffer2 <= IDLE;
        idle_cmp1 <= (state == IDLE);
        idle_cmp2 <= (state == IDLE);
        idle_cmp3 <= (state == IDLE);
        idle_cmp4 <= (state == IDLE);
        
        // 计数器零检测缓冲
        cnt_zero_flag1 <= (cnt == 5'd0);
        cnt_zero_flag2 <= (cnt == 5'd0);
        
        // 移位完成标志
        shift_done_flag <= (state == SHIFT) && (cnt <= 5'd1);
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        cnt <= 5'b0;
        result <= 32'b0;
        done <= 1'b0;
        ready_for_next <= 1'b1;
        
        // 重置流水线寄存器
        data_stage1 <= 32'b0;
        data_stage2 <= 32'b0;
        total_shift_stage1 <= 5'b0;
        total_shift_stage2 <= 5'b0;
        valid_stage1 <= 1'b0;
        valid_stage2 <= 1'b0;
        valid_stage3 <= 1'b0;
        partial_result <= 32'b0;
    end else begin
        // 流水线阶段1：输入捕获和准备
        if (start && valid_in && ready_for_next) begin
            data_stage1 <= data;
            total_shift_stage1 <= total_shift;
            valid_stage1 <= 1'b1;
            ready_for_next <= 1'b0; // 正在处理，不能接收新输入
        end else if (state == FINISH) begin
            valid_stage1 <= 1'b0;
            ready_for_next <= 1'b1; // 已完成，可以接收新输入
        end
        
        // 流水线阶段2：初始化移位操作
        data_stage2 <= data_stage1;
        total_shift_stage2 <= total_shift_stage1;
        valid_stage2 <= valid_stage1;
        
        // 流水线阶段3：状态控制
        valid_stage3 <= valid_stage2;
        
        // FSM控制逻辑 - 使用缓冲信号
        case(state)
            IDLE: begin
                done <= 1'b0;
                if (valid_stage2) begin
                    state <= LOAD;
                end
            end
            
            LOAD: begin
                if (valid_stage3) begin
                    partial_result <= data_stage2;
                    cnt <= total_shift_stage2;
                    state <= |total_shift_stage2 ? SHIFT : FINISH;
                end else begin
                    state <= idle_buffer1; // 使用缓冲信号
                end
            end
            
            SHIFT: begin
                if (!cnt_zero_flag1) begin // 使用缓冲标志
                    partial_result <= partial_result << 1;
                    cnt <= cnt - 5'd1;
                end else begin
                    state <= FINISH;
                end
                
                // 提前检测是否完成以减少关键路径
                if (shift_done_flag) begin
                    state <= FINISH;
                end
            end
            
            FINISH: begin
                result <= partial_result;
                done <= 1'b1;
                state <= idle_buffer2; // 使用缓冲信号
            end
            
            default: state <= idle_buffer1; // 使用缓冲信号
        endcase
    end
end

endmodule