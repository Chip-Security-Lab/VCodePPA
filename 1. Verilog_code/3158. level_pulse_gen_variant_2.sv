//SystemVerilog
module level_pulse_gen(
    input clock,
    input trigger,
    input [3:0] pulse_width,
    output reg pulse
);

    // 输入信号寄存器
    reg trigger_reg;
    reg [3:0] pulse_width_reg;
    
    // 状态控制信号
    reg [3:0] counter;
    reg triggered;
    
    // 加法器相关信号
    wire [3:0] sum;
    wire [3:0] p, g;
    wire [3:0] p_stage1, g_stage1;
    wire [3:0] p_stage2, g_stage2;
    wire [3:0] carry;
    reg [3:0] sum_reg;

    // 输入信号同步
    always @(posedge clock) begin
        trigger_reg <= trigger;
        pulse_width_reg <= pulse_width;
    end

    // 加法器第一阶段
    assign p = counter | 4'b0001;
    assign g = counter & 4'b0001;

    // 加法器第二阶段
    assign p_stage1[0] = p[0];
    assign g_stage1[0] = g[0];
    assign p_stage1[1] = p[1] & p[0];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    assign p_stage1[2] = p[2] & p[1];
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    assign p_stage1[3] = p[3] & p[2];
    assign g_stage1[3] = g[3] | (p[3] & g[2]);

    // 加法器第三阶段
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[1] = p_stage1[1];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    assign p_stage2[3] = p_stage1[3] & p_stage1[1];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);

    // 进位计算
    assign carry[0] = 1'b0;
    assign carry[1] = g_stage2[0];
    assign carry[2] = g_stage2[1];
    assign carry[3] = g_stage2[2];

    // 和计算
    assign sum = p ^ carry;

    // 加法结果寄存
    always @(posedge clock) begin
        sum_reg <= sum;
    end

    // 触发状态控制
    always @(posedge clock) begin
        if (trigger_reg && !triggered) begin
            triggered <= 1'b1;
        end
    end

    // 计数器控制
    always @(posedge clock) begin
        if (trigger_reg && !triggered) begin
            counter <= 4'd0;
        end else if (triggered) begin
            if (counter != pulse_width_reg - 1) begin
                counter <= sum_reg;
            end
        end
    end

    // 脉冲输出控制
    always @(posedge clock) begin
        if (trigger_reg && !triggered) begin
            pulse <= 1'b1;
        end else if (triggered && (counter == pulse_width_reg - 1)) begin
            pulse <= 1'b0;
            triggered <= 1'b0;
        end
    end

endmodule