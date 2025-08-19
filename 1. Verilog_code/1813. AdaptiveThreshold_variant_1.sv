//SystemVerilog
module AdaptiveThreshold #(parameter W=8) (
    input clk,
    input rst,  // 添加重置信号
    input [W-1:0] signal,
    input valid_in,  // 输入有效信号
    output reg valid_out,  // 输出有效信号
    output reg [W-1:0] threshold
);
    // 分离平均计算逻辑，减少关键路径
    reg [W+3:0] sum;
    
    // 流水线寄存器
    reg [W-1:0] signal_stage1;
    reg [W+3:0] sum_stage1;
    reg [W+3:0] sum_stage2;
    reg [W-1:0] avg_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线：信号输入和存储
    always @(posedge clk) begin
        if (rst) begin
            signal_stage1 <= 0;
            sum_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            signal_stage1 <= signal;
            sum_stage1 <= sum;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：累加和计算
    always @(posedge clk) begin
        if (rst) begin
            sum_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            if (valid_stage1) begin
                sum_stage2 <= sum_stage1 + signal_stage1 - sum_stage1[W+3:W];
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：平均值计算
    always @(posedge clk) begin
        if (rst) begin
            avg_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            if (valid_stage2) begin
                avg_stage3 <= sum_stage2[W+3:W] >> 2;
            end
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 第四级流水线：阈值输出
    always @(posedge clk) begin
        if (rst) begin
            threshold <= 0;
            valid_out <= 0;
        end else begin
            if (valid_stage3) begin
                threshold <= avg_stage3;
            end
            valid_out <= valid_stage3;
        end
    end
    
    // 更新sum寄存器
    always @(posedge clk) begin
        if (rst) begin
            sum <= 0;
        end else if (valid_stage2) begin
            sum <= sum_stage2;
        end
    end
endmodule