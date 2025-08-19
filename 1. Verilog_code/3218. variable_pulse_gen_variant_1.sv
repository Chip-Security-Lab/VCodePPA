//SystemVerilog
module variable_pulse_gen(
    input CLK,
    input RST,
    input [9:0] PULSE_WIDTH,
    input [9:0] PERIOD,
    output reg PULSE
);
    reg [9:0] counter;
    reg [9:0] pulse_width_reg, period_reg;
    
    // 拆分计数器逻辑
    wire counter_at_period;
    wire counter_lt_pulse;
    reg pulse_next;
    
    // 并行加法的优化实现
    wire [9:0] next_counter;
    wire [4:0] carry_lower, carry_upper;
    
    // 注册输入信号，提前捕获
    always @(posedge CLK) begin
        if (RST) begin
            pulse_width_reg <= 10'd0;
            period_reg <= 10'd0;
        end else begin
            pulse_width_reg <= PULSE_WIDTH;
            period_reg <= PERIOD;
        end
    end
    
    // 预先计算状态条件，减少关键路径
    assign counter_at_period = (counter >= period_reg);
    assign counter_lt_pulse = (counter < pulse_width_reg);
    
    // 优化的并行加法器结构 - 拆分为上下两部分并行计算
    // 下半部分加法器 (bits 0-4)
    assign carry_lower[0] = 1'b1; // 初始进位为1（加1操作）
    assign carry_lower[1] = counter[0] & carry_lower[0];
    assign carry_lower[2] = counter[1] & carry_lower[1];
    assign carry_lower[3] = counter[2] & carry_lower[2];
    assign carry_lower[4] = counter[3] & carry_lower[3];
    
    assign next_counter[0] = counter[0] ^ carry_lower[0];
    assign next_counter[1] = counter[1] ^ carry_lower[1];
    assign next_counter[2] = counter[2] ^ carry_lower[2];
    assign next_counter[3] = counter[3] ^ carry_lower[3];
    assign next_counter[4] = counter[4] ^ carry_lower[4];
    
    // 上半部分加法器 (bits 5-9)
    assign carry_upper[0] = counter[4] & carry_lower[4];
    assign carry_upper[1] = counter[5] & carry_upper[0];
    assign carry_upper[2] = counter[6] & carry_upper[1];
    assign carry_upper[3] = counter[7] & carry_upper[2];
    assign carry_upper[4] = counter[8] & carry_upper[3];
    
    assign next_counter[5] = counter[5] ^ carry_upper[0];
    assign next_counter[6] = counter[6] ^ carry_upper[1];
    assign next_counter[7] = counter[7] ^ carry_upper[2];
    assign next_counter[8] = counter[8] ^ carry_upper[3];
    assign next_counter[9] = counter[9] ^ carry_upper[4];
    
    // 将脉冲计算移至寄存器阶段前计算
    always @(*) begin
        pulse_next = counter_lt_pulse;
    end
    
    // 控制逻辑 - 使用预计算条件
    always @(posedge CLK) begin
        if (RST) begin
            counter <= 10'd0;
            PULSE <= 1'b0;
        end else begin
            counter <= counter_at_period ? 10'd0 : next_counter;
            PULSE <= pulse_next;
        end
    end
endmodule