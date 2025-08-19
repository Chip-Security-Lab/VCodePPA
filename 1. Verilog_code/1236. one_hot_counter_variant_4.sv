//SystemVerilog
module one_hot_counter (
    input wire clock, reset_n,
    input wire enable,         // 添加使能信号，控制计数器何时前进
    output reg [7:0] one_hot,
    output reg valid_out       // 流水线有效输出信号
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 流水线数据寄存器
    reg [7:0] one_hot_stage1;
    reg [7:0] one_hot_stage2;
    
    // 第一级流水线 - 初始计算并更新一位热编码
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            one_hot_stage1 <= 8'b00000001;
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            one_hot_stage1 <= {one_hot[6:0], one_hot[7]};
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线 - 中间处理阶段
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            one_hot_stage2 <= 8'b00000001;
            valid_stage2 <= 1'b0;
        end
        else begin
            one_hot_stage2 <= one_hot_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 最终输出阶段
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            one_hot <= 8'b00000001;
            valid_out <= 1'b0;
        end
        else begin
            one_hot <= one_hot_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule