//SystemVerilog
module parameterized_type_comp #(
    parameter WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter PIPELINE_STAGES = 3  // 根据WIDTH大小可调整流水线级数
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] inputs [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] max_idx,
    output reg valid
);
    // 常量定义
    localparam IDX_WIDTH = $clog2(WIDTH);
    localparam ITEMS_PER_STAGE = (WIDTH + PIPELINE_STAGES - 1) / PIPELINE_STAGES;
    
    // 流水线寄存器
    reg [DATA_WIDTH-1:0] max_value_stage [0:PIPELINE_STAGES-1];
    reg [IDX_WIDTH-1:0] max_idx_stage [0:PIPELINE_STAGES-1];
    reg valid_stage [0:PIPELINE_STAGES-1];
    
    integer i, j, stage_start, stage_end;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin
                max_value_stage[i] <= 0;
                max_idx_stage[i] <= 0;
                valid_stage[i] <= 0;
            end
            max_idx <= 0;
            valid <= 0;
        end else begin
            // 第一级流水线 - 初始化
            max_value_stage[0] <= inputs[0];
            max_idx_stage[0] <= 0;
            valid_stage[0] <= 1;
            
            // 各级流水线处理
            for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin
                stage_start = i * ITEMS_PER_STAGE + (i > 0 ? 1 : 0);
                stage_end = ((i+1) * ITEMS_PER_STAGE < WIDTH) ? (i+1) * ITEMS_PER_STAGE : WIDTH-1;
                
                if (i == 0) begin
                    // 第一级流水线比较
                    for (j = stage_start + 1; j <= stage_end && j < WIDTH; j = j + 1) begin
                        if (inputs[j] > max_value_stage[0]) begin
                            max_value_stage[0] <= inputs[j];
                            max_idx_stage[0] <= j[IDX_WIDTH-1:0];
                        end
                    end
                end else begin
                    // 后续流水线级传递前一级结果
                    max_value_stage[i] <= max_value_stage[i-1];
                    max_idx_stage[i] <= max_idx_stage[i-1];
                    valid_stage[i] <= valid_stage[i-1];
                    
                    // 比较此级分配的元素
                    for (j = stage_start; j <= stage_end && j < WIDTH; j = j + 1) begin
                        if (inputs[j] > max_value_stage[i]) begin
                            max_value_stage[i] <= inputs[j];
                            max_idx_stage[i] <= j[IDX_WIDTH-1:0];
                        end
                    end
                end
            end
            
            // 输出最终结果
            max_idx <= max_idx_stage[PIPELINE_STAGES-1];
            valid <= valid_stage[PIPELINE_STAGES-1];
        end
    end
endmodule