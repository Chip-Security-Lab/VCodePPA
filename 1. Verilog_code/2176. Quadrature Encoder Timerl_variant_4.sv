//SystemVerilog
module quad_encoder_timer (
    input wire clk, rst, quad_a, quad_b, timer_en,
    input wire data_valid_in,  // 输入数据有效信号
    output wire data_valid_out, // 输出数据有效信号
    output reg [15:0] position,
    output reg [31:0] timer
);
    // 流水线阶段寄存器
    // 阶段1 - 输入采样和四相编码状态确定
    reg a_sampled_stage1, b_sampled_stage1;
    reg a_prev_stage1, b_prev_stage1;
    reg [1:0] quad_state_stage1, quad_state_prev_stage1;
    reg valid_stage1;
    
    // 阶段2 - 状态转换检测
    reg [1:0] quad_state_stage2, quad_state_prev_stage2;
    reg state_changed_stage2;
    reg [3:0] transition_pattern_stage2;
    reg valid_stage2;
    
    // 阶段3 - 位置计算准备
    reg state_changed_stage3;
    reg position_inc_stage3;
    reg position_dec_stage3;
    reg [15:0] position_stage3;
    reg valid_stage3;
    
    // 阶段4 - 位置和计时器更新
    reg timer_en_stage4;
    reg valid_stage4;
    
    // 阶段1 - 输入采样和状态确定
    always @(posedge clk) begin
        if (rst) begin
            a_sampled_stage1 <= 1'b0;
            b_sampled_stage1 <= 1'b0;
            a_prev_stage1 <= 1'b0;
            b_prev_stage1 <= 1'b0;
            quad_state_stage1 <= 2'b00;
            quad_state_prev_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end
        else begin
            a_sampled_stage1 <= quad_a;
            b_sampled_stage1 <= quad_b;
            a_prev_stage1 <= a_sampled_stage1;
            b_prev_stage1 <= b_sampled_stage1;
            quad_state_stage1 <= {a_sampled_stage1, b_sampled_stage1};
            quad_state_prev_stage1 <= quad_state_stage1;
            valid_stage1 <= data_valid_in;
        end
    end
    
    // 阶段2 - 状态转换检测
    always @(posedge clk) begin
        if (rst) begin
            quad_state_stage2 <= 2'b00;
            quad_state_prev_stage2 <= 2'b00;
            state_changed_stage2 <= 1'b0;
            transition_pattern_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else begin
            quad_state_stage2 <= quad_state_stage1;
            quad_state_prev_stage2 <= quad_state_prev_stage1;
            state_changed_stage2 <= (quad_state_stage1 != quad_state_prev_stage1);
            transition_pattern_stage2 <= {quad_state_prev_stage1, quad_state_stage1};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3 - 位置计算准备
    always @(posedge clk) begin
        if (rst) begin
            state_changed_stage3 <= 1'b0;
            position_inc_stage3 <= 1'b0;
            position_dec_stage3 <= 1'b0;
            position_stage3 <= 16'h0000;
            valid_stage3 <= 1'b0;
        end
        else begin
            state_changed_stage3 <= state_changed_stage2;
            position_stage3 <= position;
            valid_stage3 <= valid_stage2;
            
            // 解码状态转换模式
            case (transition_pattern_stage2)
                // 顺时针旋转模式
                4'b0001, 4'b0111, 4'b1110, 4'b1000: begin
                    position_inc_stage3 <= state_changed_stage2;
                    position_dec_stage3 <= 1'b0;
                end
                // 逆时针旋转模式
                4'b0010, 4'b0100, 4'b1101, 4'b1011: begin
                    position_inc_stage3 <= 1'b0;
                    position_dec_stage3 <= state_changed_stage2;
                end
                // 其他状态保持不变
                default: begin
                    position_inc_stage3 <= 1'b0;
                    position_dec_stage3 <= 1'b0;
                end
            endcase
        end
    end
    
    // 阶段4 - 位置和计时器更新
    always @(posedge clk) begin
        if (rst) begin
            position <= 16'h0000;
            timer <= 32'h0;
            timer_en_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end
        else begin
            // 更新位置
            if (position_inc_stage3) begin
                position <= position_stage3 + 16'h0001;
            end
            else if (position_dec_stage3) begin
                position <= position_stage3 - 16'h0001;
            end
            
            // 更新计时器
            timer_en_stage4 <= timer_en;
            if (timer_en_stage4) begin
                timer <= timer + 32'h1;
            end
            
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 输出有效信号
    assign data_valid_out = valid_stage4;
    
endmodule