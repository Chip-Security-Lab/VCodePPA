//SystemVerilog
module multi_mode_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    input wire [WIDTH-1:0] period,
    output reg out
);
    // 流水线寄存器声明
    reg [WIDTH-1:0] counter_stage1, counter_stage2;
    reg [1:0] mode_stage1, mode_stage2;
    reg [WIDTH-1:0] period_stage1, period_stage2;
    reg out_stage1, out_stage2;
    reg counter_updating;
    
    // 计算单元分解到多级
    wire [WIDTH-1:0] period_minus_one_stage1;
    wire [WIDTH-1:0] half_period_stage1;
    reg [WIDTH-1:0] period_minus_one_stage2;
    reg [WIDTH-1:0] half_period_stage2;
    
    // 比较结果寄存器
    wire counter_reach_period_stage1;
    wire counter_less_than_half_stage1;
    reg counter_reach_period_stage2;
    reg counter_less_than_half_stage2;
    
    // 第一级计算
    assign period_minus_one_stage1 = period + {WIDTH{1'b1}}; // period - 1
    assign half_period_stage1 = {1'b0, period[WIDTH-1:1]}; // period >> 1
    
    // 第一级流水线 - 寄存流水线输入和中间计算结果
    always @(posedge clk) begin
        if (rst) begin
            mode_stage1 <= 2'b0;
            period_stage1 <= {WIDTH{1'b0}};
            counter_stage1 <= {WIDTH{1'b0}};
            period_minus_one_stage2 <= {WIDTH{1'b0}};
            half_period_stage2 <= {WIDTH{1'b0}};
        end else begin
            mode_stage1 <= mode;
            period_stage1 <= period;
            counter_stage1 <= counter_updating ? counter_stage2 : counter_stage2 + 1'b1;
            period_minus_one_stage2 <= period_minus_one_stage1;
            half_period_stage2 <= half_period_stage1;
        end
    end
    
    // 第二级流水线 - 进行比较操作
    always @(posedge clk) begin
        if (rst) begin
            counter_reach_period_stage2 <= 1'b0;
            counter_less_than_half_stage2 <= 1'b0;
            mode_stage2 <= 2'b0;
            counter_stage2 <= {WIDTH{1'b0}};
            period_stage2 <= {WIDTH{1'b0}};
        end else begin
            counter_reach_period_stage2 <= (counter_stage1 == period_minus_one_stage2);
            counter_less_than_half_stage2 <= (counter_stage1 < half_period_stage2);
            mode_stage2 <= mode_stage1;
            counter_stage2 <= counter_stage1;
            period_stage2 <= period_stage1;
        end
    end
    
    // 第三级流水线 - 模式逻辑与输出生成
    always @(posedge clk) begin
        if (rst) begin
            out <= 1'b0;
            counter_updating <= 1'b0;
            out_stage1 <= 1'b0;
            out_stage2 <= 1'b0;
        end else begin
            out_stage1 <= out_stage2;
            out <= out_stage1;
            
            case (mode_stage2)
                2'd0: begin // One-Shot Mode
                    if (counter_stage2 < period_stage2) begin
                        counter_updating <= 1'b0;
                        out_stage2 <= 1'b1;
                    end else begin
                        counter_updating <= 1'b1;
                        out_stage2 <= 1'b0;
                    end
                end
                2'd1: begin // Periodic Mode
                    if (counter_reach_period_stage2) begin
                        counter_updating <= 1'b1;
                        out_stage2 <= 1'b1;
                    end else begin
                        counter_updating <= 1'b0;
                        out_stage2 <= 1'b0;
                    end
                end
                2'd2: begin // PWM Mode (50% duty)
                    if (counter_reach_period_stage2) begin
                        counter_updating <= 1'b1;
                    end else begin
                        counter_updating <= 1'b0;
                    end
                    out_stage2 <= counter_less_than_half_stage2 ? 1'b1 : 1'b0;
                end
                2'd3: begin // Toggle Mode
                    if (counter_reach_period_stage2) begin
                        counter_updating <= 1'b1;
                        out_stage2 <= ~out_stage1;
                    end else begin
                        counter_updating <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule