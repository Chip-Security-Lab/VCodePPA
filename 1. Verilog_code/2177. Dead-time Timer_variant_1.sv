//SystemVerilog
module deadtime_timer (
    input wire clk, rst_n,
    input wire [15:0] period, duty,
    input wire [7:0] deadtime,
    output wire pwm_high, pwm_low
);
    wire [15:0] counter;
    wire compare_match;
    
    // 实例化子模块
    counter_module counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .period(period),
        .counter(counter)
    );
    
    comparator_module comparator_inst (
        .counter(counter),
        .duty(duty),
        .compare_match(compare_match)
    );
    
    pwm_generator_module pwm_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .counter(counter),
        .compare_match(compare_match),
        .period(period),
        .duty(duty),
        .deadtime(deadtime),
        .pwm_high(pwm_high),
        .pwm_low(pwm_low)
    );
endmodule

module counter_module (
    input wire clk, rst_n,
    input wire [15:0] period,
    output reg [15:0] counter
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 16'd0;
        else 
            counter <= (counter >= period - 1) ? 16'd0 : counter + 16'd1;
    end
endmodule

module comparator_module (
    input wire [15:0] counter,
    input wire [15:0] duty,
    output wire compare_match
);
    assign compare_match = (counter < duty);
endmodule

module pwm_generator_module (
    input wire clk, rst_n,
    input wire [15:0] counter,
    input wire compare_match,
    input wire [15:0] period, duty,
    input wire [7:0] deadtime,
    output reg pwm_high, pwm_low
);
    // 状态编码 - 使用查找表结构优化
    reg [2:0] pwm_state;
    wire [1:0] pwm_out;
    
    // 状态计算逻辑
    always @(*) begin
        pwm_state[0] = compare_match;
        pwm_state[1] = (counter >= deadtime);
        pwm_state[2] = (counter >= (period - deadtime) || counter < (period - duty));
    end
    
    // 查找表 - 预计算输出逻辑
    reg [1:0] pwm_lut [0:7];
    
    // 初始化查找表
    initial begin
        // 格式: {pwm_high, pwm_low}
        pwm_lut[3'b000] = 2'b00; // compare_match=0, counter<deadtime, counter<(period-deadtime)&&counter>=(period-duty)
        pwm_lut[3'b001] = 2'b01; // compare_match=0, counter<deadtime, counter>=(period-deadtime)||counter<(period-duty)
        pwm_lut[3'b010] = 2'b00; // compare_match=0, counter>=deadtime, counter<(period-deadtime)&&counter>=(period-duty)
        pwm_lut[3'b011] = 2'b01; // compare_match=0, counter>=deadtime, counter>=(period-deadtime)||counter<(period-duty)
        pwm_lut[3'b100] = 2'b00; // compare_match=1, counter<deadtime, counter<(period-deadtime)&&counter>=(period-duty)
        pwm_lut[3'b101] = 2'b00; // compare_match=1, counter<deadtime, counter>=(period-deadtime)||counter<(period-duty)
        pwm_lut[3'b110] = 2'b10; // compare_match=1, counter>=deadtime, counter<(period-deadtime)&&counter>=(period-duty)
        pwm_lut[3'b111] = 2'b10; // compare_match=1, counter>=deadtime, counter>=(period-deadtime)||counter<(period-duty)
    end
    
    // 使用状态作为索引查找输出
    assign pwm_out = pwm_lut[pwm_state];
    
    // 寄存状态输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            pwm_high <= 1'b0; 
            pwm_low <= 1'b0; 
        end
        else begin
            pwm_high <= pwm_out[1];
            pwm_low <= pwm_out[0];
        end
    end
endmodule