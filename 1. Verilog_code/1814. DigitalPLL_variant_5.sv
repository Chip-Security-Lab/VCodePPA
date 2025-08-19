//SystemVerilog
module DigitalPLL #(parameter PHASE_BITS=10) (
    input clk, rst,
    input data_in,
    output reg data_sync,
    // 添加流水线控制信号
    input valid_in,
    output reg valid_out
);
    // 流水线阶段1：相位计算
    reg [PHASE_BITS-1:0] phase_acc_stage1;
    reg [PHASE_BITS-1:0] increment_stage1;
    reg valid_stage1;
    reg data_in_stage1;
    
    // 流水线阶段2：输出生成
    reg [PHASE_BITS-1:0] phase_acc_stage2;
    reg valid_stage2;
    
    // 定义常量
    parameter [PHASE_BITS-1:0] FAST_INC = 100;
    parameter [PHASE_BITS-1:0] SLOW_INC = 90;
    
    // 阶段1：计算增量与相位累加
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc_stage1 <= 0;
            increment_stage1 <= 0;
            valid_stage1 <= 0;
            data_in_stage1 <= 0;
        end else begin
            if (valid_in) begin
                increment_stage1 <= data_in ? FAST_INC : SLOW_INC;
                phase_acc_stage1 <= (phase_acc_stage2 + (data_in ? FAST_INC : SLOW_INC));
                data_in_stage1 <= data_in;
            end
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2：生成同步输出
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            phase_acc_stage2 <= 0;
            data_sync <= 0;
            valid_stage2 <= 0;
            valid_out <= 0;
        end else begin
            if (valid_stage1) begin
                phase_acc_stage2 <= phase_acc_stage1;
                data_sync <= phase_acc_stage1[PHASE_BITS-1];
            end
            valid_stage2 <= valid_stage1;
            valid_out <= valid_stage2;
        end
    end
endmodule