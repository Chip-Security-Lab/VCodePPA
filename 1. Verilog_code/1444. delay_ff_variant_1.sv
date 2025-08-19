//SystemVerilog
module delay_ff #(
    parameter STAGES = 2  // 流水线级数参数
) (
    input  wire       clk,      // 时钟信号
    input  wire       rst_n,    // 异步低电平复位信号
    input  wire       d_valid,  // 输入数据有效信号
    input  wire       d,        // 输入数据
    output wire       q,        // 输出数据
    output wire       q_valid   // 输出数据有效信号
);
    
    // 数据流水线阶段定义
    reg [STAGES-1:0] data_pipeline;
    
    // 控制流水线阶段定义 - 追踪每个阶段的数据有效性
    reg [STAGES-1:0] valid_pipeline;
    
    // 流水线阶段1输入寄存器 - 接收输入数据
    wire stage1_data_in = d;
    wire stage1_valid_in = d_valid;
    
    // 流水线主体逻辑 - 多级延迟管道
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位 - 清空所有流水线阶段
            data_pipeline <= {STAGES{1'b0}};
            valid_pipeline <= {STAGES{1'b0}};
        end 
        else begin
            // 第一级流水线处理
            data_pipeline[0] <= stage1_data_in;
            valid_pipeline[0] <= stage1_valid_in;
            
            // 后续流水线级联处理 - 数据向下传递
            for (i = 1; i < STAGES; i = i + 1) begin
                data_pipeline[i] <= data_pipeline[i-1];
                valid_pipeline[i] <= valid_pipeline[i-1];
            end
        end
    end
    
    // 输出阶段 - 最终流水线输出
    wire final_stage_data = data_pipeline[STAGES-1];
    wire final_stage_valid = valid_pipeline[STAGES-1];
    
    // 输出信号分配
    assign q = final_stage_data;
    assign q_valid = final_stage_valid;
    
endmodule