//SystemVerilog
// 顶层模块
module pwm_dead_time (
    input clk,
    input rst,
    input [7:0] duty,
    input [3:0] dead_time,
    output pwm_high,
    output pwm_low
);
    // 内部连线
    wire [7:0] counter_value;
    
    // 子模块实例化
    counter_module counter_inst (
        .clk(clk),
        .rst(rst),
        .counter(counter_value)
    );
    
    pwm_generator pwm_gen_inst (
        .clk(clk),
        .rst(rst),
        .counter(counter_value),
        .duty(duty),
        .dead_time(dead_time),
        .pwm_high(pwm_high),
        .pwm_low(pwm_low)
    );
    
endmodule

// 计数器子模块
module counter_module (
    input clk,
    input rst,
    output reg [7:0] counter
);
    // 先行进位加法器内部信号
    wire [7:0] sum;
    wire [7:0] p, g;
    wire [8:0] c;
    
    // 生成传播位和生成位
    assign p = counter;
    assign g = 8'h00;  // 加1操作的生成位
    assign c[0] = 1'b1; // 加1操作的初始进位
    
    // 先行进位逻辑
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    
    // 求和逻辑
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
    
    // 计数器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'd0;
        end else begin
            counter <= sum;
        end
    end
endmodule

// PWM生成器子模块
module pwm_generator (
    input clk,
    input rst,
    input [7:0] counter,
    input [7:0] duty,
    input [3:0] dead_time,
    output reg pwm_high,
    output reg pwm_low
);
    // 计算duty+dead_time的先行进位加法器
    wire [7:0] duty_plus_dt;
    wire [7:0] p_add, g_add;
    wire [8:0] c_add;
    wire [3:0] extended_dt;
    
    // 扩展dead_time为8位
    assign extended_dt = dead_time;
    
    // 生成传播位和生成位
    assign p_add = duty | {4'b0000, extended_dt};
    assign g_add = duty & {4'b0000, extended_dt};
    assign c_add[0] = 1'b0;
    
    // 先行进位逻辑
    assign c_add[1] = g_add[0] | (p_add[0] & c_add[0]);
    assign c_add[2] = g_add[1] | (p_add[1] & g_add[0]) | (p_add[1] & p_add[0] & c_add[0]);
    assign c_add[3] = g_add[2] | (p_add[2] & g_add[1]) | (p_add[2] & p_add[1] & g_add[0]) | (p_add[2] & p_add[1] & p_add[0] & c_add[0]);
    assign c_add[4] = g_add[3] | (p_add[3] & g_add[2]) | (p_add[3] & p_add[2] & g_add[1]) | (p_add[3] & p_add[2] & p_add[1] & g_add[0]) | (p_add[3] & p_add[2] & p_add[1] & p_add[0] & c_add[0]);
    assign c_add[5] = g_add[4] | (p_add[4] & c_add[4]);
    assign c_add[6] = g_add[5] | (p_add[5] & c_add[5]);
    assign c_add[7] = g_add[6] | (p_add[6] & c_add[6]);
    assign c_add[8] = g_add[7] | (p_add[7] & c_add[7]);
    
    // 求和逻辑
    assign duty_plus_dt[0] = duty[0] ^ extended_dt[0] ^ c_add[0];
    assign duty_plus_dt[1] = duty[1] ^ (extended_dt[1]) ^ c_add[1];
    assign duty_plus_dt[2] = duty[2] ^ (extended_dt[2]) ^ c_add[2];
    assign duty_plus_dt[3] = duty[3] ^ (extended_dt[3]) ^ c_add[3];
    assign duty_plus_dt[4] = duty[4] ^ 1'b0 ^ c_add[4];
    assign duty_plus_dt[5] = duty[5] ^ 1'b0 ^ c_add[5];
    assign duty_plus_dt[6] = duty[6] ^ 1'b0 ^ c_add[6];
    assign duty_plus_dt[7] = duty[7] ^ 1'b0 ^ c_add[7];
    
    // PWM信号生成逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_high <= 1'b0;
            pwm_low <= 1'b0;
        end else begin
            // 高侧PWM信号生成
            pwm_high <= (counter < duty) ? 1'b1 : 1'b0;
            
            // 低侧PWM信号生成（考虑死区时间）
            pwm_low <= (counter > duty_plus_dt) ? 1'b1 : 1'b0;
        end
    end
endmodule