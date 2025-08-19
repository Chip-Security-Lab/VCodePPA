//SystemVerilog
module param_square_wave #(
    parameter WIDTH = 16
)(
    input clock_i,
    input reset_i,
    input [WIDTH-1:0] period_i,
    input [WIDTH-1:0] duty_i,
    output reg wave_o
);
    // 将计数器逻辑拆分成多级流水线
    reg [WIDTH-1:0] counter_r;
    reg [WIDTH-1:0] period_stage1, period_stage2;
    reg [WIDTH-1:0] duty_stage1, duty_stage2, duty_stage3;
    reg counter_reset_stage1, counter_reset_stage2;
    reg compare_result_stage1;

    // 第一级流水线：周期值寄存和复位条件计算
    always @(posedge clock_i) begin
        if (reset_i) begin
            period_stage1 <= {WIDTH{1'b0}};
            counter_reset_stage1 <= 1'b0;
        end else begin
            period_stage1 <= period_i;
            counter_reset_stage1 <= (counter_r >= period_i - 1'b1);
        end
        duty_stage1 <= duty_i;
    end

    // 第二级流水线：计数器计算和周期比较逻辑
    always @(posedge clock_i) begin
        if (reset_i) begin
            counter_r <= {WIDTH{1'b0}};
            period_stage2 <= {WIDTH{1'b0}};
            counter_reset_stage2 <= 1'b0;
        end else begin
            period_stage2 <= period_stage1;
            counter_reset_stage2 <= counter_reset_stage1;
            
            if (counter_reset_stage2)
                counter_r <= {WIDTH{1'b0}};
            else
                counter_r <= counter_r + 1'b1;
        end
        duty_stage2 <= duty_stage1;
    end

    // 第三级流水线：占空比比较逻辑
    always @(posedge clock_i) begin
        if (reset_i) begin
            duty_stage3 <= {WIDTH{1'b0}};
            compare_result_stage1 <= 1'b0;
        end else begin
            duty_stage3 <= duty_stage2;
            compare_result_stage1 <= (counter_r < duty_stage2);
        end
    end

    // 输出级：波形输出
    always @(posedge clock_i) begin
        if (reset_i)
            wave_o <= 1'b0;
        else
            wave_o <= compare_result_stage1;
    end
endmodule