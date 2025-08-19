//SystemVerilog
module param_reset_ctrl #(
    parameter WIDTH = 4,
    parameter ACTIVE_HIGH = 1,
    parameter PIPELINE_STAGES = 3  // 增加默认流水线深度
)(
    input wire clk,
    input wire reset_in,
    input wire enable,
    output reg [WIDTH-1:0] reset_out
);
    // 阶段1: 输入寄存器 - 对输入信号进行寄存
    reg reset_in_stage1;
    reg enable_stage1;
    
    always @(posedge clk) begin
        reset_in_stage1 <= reset_in;
        enable_stage1 <= enable;
    end
    
    // 阶段2: 极性调整寄存器
    reg reset_polarity_adjusted_stage2;
    reg enable_stage2;
    
    always @(posedge clk) begin
        reset_polarity_adjusted_stage2 <= ACTIVE_HIGH ? reset_in_stage1 : ~reset_in_stage1;
        enable_stage2 <= enable_stage1;
    end
    
    // 阶段3: 使能控制寄存器
    reg reset_enabled_stage3;
    
    always @(posedge clk) begin
        reset_enabled_stage3 <= enable_stage2 ? reset_polarity_adjusted_stage2 : 1'b0;
    end
    
    // 阶段4+: 流水线延迟寄存器
    reg [PIPELINE_STAGES-1:0] reset_pipeline_stages;
    
    // 第一级流水线寄存器
    always @(posedge clk) begin
        if (PIPELINE_STAGES > 0)
            reset_pipeline_stages[0] <= reset_enabled_stage3;
    end
    
    // 流水线寄存器级联
    genvar i;
    generate
        for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : reset_pipe
            always @(posedge clk) begin
                reset_pipeline_stages[i] <= reset_pipeline_stages[i-1];
            end
        end
    endgenerate
    
    // 最终阶段: 输出扩展逻辑
    reg [WIDTH-1:0] reset_out_temp;
    
    always @(posedge clk) begin
        if (PIPELINE_STAGES > 0)
            reset_out_temp <= {WIDTH{reset_pipeline_stages[PIPELINE_STAGES-1]}};
        else
            reset_out_temp <= {WIDTH{reset_enabled_stage3}};
    end
    
    // 输出寄存器 - 增加额外一级寄存减少输出路径延迟
    always @(posedge clk) begin
        reset_out <= reset_out_temp;
    end
    
    // 复位传播路径信息
    // synthesis attribute keep_hierarchy of param_reset_ctrl is "yes"
    // synthesis attribute EQUIVALENT_REGISTER_REMOVAL of reset_pipeline_stages is "no"
    
endmodule