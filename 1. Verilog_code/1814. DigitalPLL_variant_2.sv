//SystemVerilog
module DigitalPLL #(parameter PHASE_BITS=10) (
    input clk, rst,
    input data_in,
    output reg data_sync
);
    // 流水线寄存器定义
    reg [PHASE_BITS-1:0] phase_acc_stage1;
    reg [PHASE_BITS-1:0] phase_acc_stage2;
    reg [PHASE_BITS-1:0] phase_acc_stage3;
    
    reg data_in_stage1;
    reg data_in_stage2;
    
    reg [PHASE_BITS-1:0] increment_stage1;
    reg [PHASE_BITS-1:0] increment_stage2;
    
    // 定义常量
    parameter [PHASE_BITS-1:0] FAST_INC = 100;
    parameter [PHASE_BITS-1:0] SLOW_INC = 90;
    
    // 第一级流水线：捕获输入
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            data_in_stage1 <= 0;
            increment_stage1 <= 0;
        end else begin
            data_in_stage1 <= data_in;
            increment_stage1 <= data_in ? FAST_INC : SLOW_INC;
        end
    end
    
    // 第二级流水线：传播增量
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            data_in_stage2 <= 0;
            increment_stage2 <= 0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            increment_stage2 <= increment_stage1;
        end
    end
    
    // 第三级流水线：计算阶段1 - 累加器初始更新
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc_stage1 <= 0;
        end else begin
            phase_acc_stage1 <= phase_acc_stage3 + increment_stage2;
        end
    end
    
    // 第四级流水线：计算阶段2 - 累加器传播
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc_stage2 <= 0;
        end else begin
            phase_acc_stage2 <= phase_acc_stage1;
        end
    end
    
    // 第五级流水线：计算阶段3 - 累加器最终状态
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc_stage3 <= 0;
        end else begin
            phase_acc_stage3 <= phase_acc_stage2;
        end
    end
    
    // 输出阶段：生成同步数据
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            data_sync <= 0;
        end else begin
            data_sync <= phase_acc_stage3[PHASE_BITS-1];
        end
    end
endmodule