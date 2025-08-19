//SystemVerilog
module TimerSync #(parameter WIDTH=16) (
    input clk, rst_n, enable,
    output reg timer_out
);
    // 将计数器分为两个流水线阶段
    reg [WIDTH-1:0] counter_stage1;
    reg counter_max_stage1;     // 第一阶段判断计数器是否达到最大值
    reg valid_stage1;           // 第一阶段有效信号
    
    reg [WIDTH-1:0] counter_stage2;
    reg counter_max_stage2;     // 第二阶段保存计数器最大值判断结果
    reg valid_stage2;           // 第二阶段有效信号
    
    // 预计算最大值常量，避免重复计算
    localparam [WIDTH-1:0] MAX_COUNT = {WIDTH{1'b1}};
    
    // 优化的比较逻辑，使用与门组合而非相等比较
    wire is_max_value = &counter_stage2;
    wire [WIDTH-1:0] next_counter = is_max_value ? {WIDTH{1'b0}} : counter_stage2 + 1'b1;

    // 流水线阶段1：计数和比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {WIDTH{1'b0}};
            counter_max_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (enable) begin
                counter_stage1 <= next_counter;
                counter_max_stage1 <= is_max_value;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // 流水线阶段2：结果传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {WIDTH{1'b0}};
            counter_max_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            timer_out <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            counter_max_stage2 <= counter_max_stage1;
            valid_stage2 <= valid_stage1;
            
            // 使用阻塞赋值更新输出，降低延迟
            if (valid_stage2)
                timer_out = counter_max_stage2;
        end
    end
endmodule