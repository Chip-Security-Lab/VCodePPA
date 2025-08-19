//SystemVerilog
module reg_config_reset(
    input wire clk,
    input wire rst_n,
    input wire [7:0] config_data,
    input wire config_valid,
    input wire reset_trigger,
    output reg [7:0] reset_out,
    output reg pipeline_valid_out
);
    // 流水线阶段寄存器
    reg [7:0] config_reg_stage1, config_reg_stage2;
    reg config_valid_stage1, pipeline_valid_stage2;
    reg reset_trigger_stage1, reset_trigger_stage2;
    
    // 流水线阶段1处理 - 配置寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg_stage1 <= 8'h0;
            config_valid_stage1 <= 1'b0;
            reset_trigger_stage1 <= 1'b0;
        end else begin
            // 条件更新配置寄存器，减少不必要的写入
            config_reg_stage1 <= config_valid ? config_data : config_reg_stage1;
            
            // 传递控制信号到下一级
            config_valid_stage1 <= config_valid;
            reset_trigger_stage1 <= reset_trigger;
        end
    end
    
    // 流水线阶段2处理 - 复位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg_stage2 <= 8'h0;
            reset_trigger_stage2 <= 1'b0;
            pipeline_valid_stage2 <= 1'b0;
        end else begin
            // 数据传递
            {config_reg_stage2, reset_trigger_stage2, pipeline_valid_stage2} <= 
            {config_reg_stage1, reset_trigger_stage1, config_valid_stage1};
        end
    end
    
    // 输出阶段 - 最终结果计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_out <= 8'h0;
            pipeline_valid_out <= 1'b0;
        end else begin
            // 使用条件赋值简化输出逻辑
            reset_out <= reset_trigger_stage2 ? config_reg_stage2 : 8'h0;
            pipeline_valid_out <= pipeline_valid_stage2;
        end
    end
endmodule