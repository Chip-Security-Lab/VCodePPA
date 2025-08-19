//SystemVerilog
// SystemVerilog
module MultiInput_AND #(
    parameter INPUTS = 4,
    parameter PIPELINE_STAGES = 2
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUTS-1:0] signals,
    input wire valid_in,
    output wire result,
    output wire valid_out
);

    // 声明内部信号和寄存器
    reg [INPUTS-1:0] signals_reg[PIPELINE_STAGES:0];
    reg valid_pipe[PIPELINE_STAGES:0];
    
    // 流水线第一级：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signals_reg[0] <= {INPUTS{1'b0}};
            valid_pipe[0] <= 1'b0;
        end else if (valid_in) begin
            signals_reg[0] <= signals;
            valid_pipe[0] <= 1'b1;
        end else begin
            signals_reg[0] <= signals;
            valid_pipe[0] <= 1'b0;
        end
    end
    
    // 生成中间流水线级
    genvar i;
    generate
        for (i = 1; i <= PIPELINE_STAGES-1; i = i + 1) begin : pipeline_stage
            // 分段计算AND操作，平衡逻辑深度
            localparam STAGE_WIDTH = INPUTS / PIPELINE_STAGES;
            localparam START_IDX = (i-1) * STAGE_WIDTH;
            localparam END_IDX = (i == PIPELINE_STAGES-1) ? INPUTS-1 : (i * STAGE_WIDTH - 1);
            
            reg stage_result;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_result <= 1'b0;
                    valid_pipe[i] <= 1'b0;
                    signals_reg[i] <= {INPUTS{1'b0}};
                end else if (valid_pipe[i-1]) begin
                    stage_result <= &signals_reg[i-1][END_IDX:START_IDX];
                    valid_pipe[i] <= 1'b1;
                    signals_reg[i] <= signals_reg[i-1];
                end else begin
                    stage_result <= 1'b0;
                    valid_pipe[i] <= 1'b0;
                    signals_reg[i] <= signals_reg[i-1];
                end
            end
        end
    endgenerate
    
    // 最终阶段：汇总所有中间结果
    reg result_reg;
    reg valid_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 1'b0;
            valid_out_reg <= 1'b0;
        end else if (valid_pipe[PIPELINE_STAGES-1]) begin
            result_reg <= &signals_reg[PIPELINE_STAGES-1];
            valid_out_reg <= 1'b1;
        end else begin
            result_reg <= 1'b0;
            valid_out_reg <= 1'b0;
        end
    end
    
    // 输出赋值
    assign result = result_reg;
    assign valid_out = valid_out_reg;

endmodule