//SystemVerilog
module digital_ctrl_osc(
    input enable,
    input [7:0] ctrl_word,
    input reset,
    input clk,  // 外部时钟输入
    output reg clk_out
);
    // 流水线阶段1: 计数和比较
    reg [7:0] delay_counter_stage1;
    reg compare_result_stage1;
    reg enable_stage1;
    reg clk_out_stage1;
    
    // 流水线阶段2: 决策和输出
    reg compare_result_stage2;
    reg enable_stage2;
    reg clk_out_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 阶段1: 信号同步和使能控制
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            enable_stage1 <= 1'b0;
            clk_out_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= enable;
            clk_out_stage1 <= clk_out;
            
            valid_stage1 <= enable ? 1'b1 : 1'b0;
        end
    end
    
    // 阶段1: 计数逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            delay_counter_stage1 <= 8'd0;
        end else if (enable) begin
            if (delay_counter_stage1 >= ctrl_word)
                delay_counter_stage1 <= 8'd0;
            else
                delay_counter_stage1 <= delay_counter_stage1 + 8'd1;
        end
    end
    
    // 阶段1: 比较结果生成
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            compare_result_stage1 <= 1'b0;
        end else if (enable) begin
            compare_result_stage1 <= (delay_counter_stage1 >= ctrl_word) ? 1'b1 : 1'b0;
        end
    end
    
    // 阶段2: 流水线寄存器传递
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            compare_result_stage2 <= 1'b0;
            enable_stage2 <= 1'b0;
            clk_out_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            compare_result_stage2 <= compare_result_stage1;
            enable_stage2 <= enable_stage1;
            clk_out_stage2 <= clk_out_stage1;
        end
    end
    
    // 阶段2: 输出时钟生成
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_out <= 1'b0;
        end else if (valid_stage2 && enable_stage2) begin
            if (compare_result_stage2)
                clk_out <= ~clk_out_stage2;
            else
                clk_out <= clk_out_stage2;
        end
    end
endmodule