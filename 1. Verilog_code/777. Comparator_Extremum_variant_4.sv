//SystemVerilog
module Comparator_Extremum #(
    parameter WIDTH = 8,
    parameter NUM_INPUTS = 4
)(
    input  [NUM_INPUTS-1:0][WIDTH-1:0] data_array,
    output [WIDTH-1:0]                 max_val,
    output [$clog2(NUM_INPUTS)-1:0]    max_idx,
    output [WIDTH-1:0]                 min_val,
    output [$clog2(NUM_INPUTS)-1:0]    min_idx
);
    // 定义本地参数
    localparam IDX_WIDTH = $clog2(NUM_INPUTS);
    
    // 比较树结构优化 - 使用组合逻辑树
    // 最大值和最小值查找使用分治策略处理
    
    // 中间变量声明
    reg [WIDTH-1:0] max_stage[NUM_INPUTS-1:0];
    reg [WIDTH-1:0] min_stage[NUM_INPUTS-1:0];
    reg [IDX_WIDTH-1:0] max_idx_stage[NUM_INPUTS-1:0];
    reg [IDX_WIDTH-1:0] min_idx_stage[NUM_INPUTS-1:0];
    
    integer i, j, stage, step;
    
    // 组合逻辑实现
    always @(*) begin
        // 初始化第一阶段
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin
            max_stage[i] = data_array[i];
            min_stage[i] = data_array[i];
            max_idx_stage[i] = i[IDX_WIDTH-1:0];
            min_idx_stage[i] = i[IDX_WIDTH-1:0];
        end
        
        // 分层比较逻辑，减少关键路径深度
        for (step = 1; step < NUM_INPUTS; step = step * 2) begin
            for (j = 0; j < NUM_INPUTS; j = j + 2*step) begin
                if (j + step < NUM_INPUTS) begin
                    // 最大值比较
                    if (max_stage[j] >= max_stage[j+step]) begin
                        max_stage[j] = max_stage[j];
                        max_idx_stage[j] = max_idx_stage[j];
                    end else begin
                        max_stage[j] = max_stage[j+step];
                        max_idx_stage[j] = max_idx_stage[j+step];
                    end
                    
                    // 最小值比较
                    if (min_stage[j] <= min_stage[j+step]) begin
                        min_stage[j] = min_stage[j];
                        min_idx_stage[j] = min_idx_stage[j];
                    end else begin
                        min_stage[j] = min_stage[j+step];
                        min_idx_stage[j] = min_idx_stage[j+step];
                    end
                end
            end
        end
    end
    
    // 最终结果
    assign max_val = max_stage[0];
    assign max_idx = max_idx_stage[0];
    assign min_val = min_stage[0];
    assign min_idx = min_idx_stage[0];
    
endmodule