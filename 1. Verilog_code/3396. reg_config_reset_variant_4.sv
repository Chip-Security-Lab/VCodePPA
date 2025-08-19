//SystemVerilog
module reg_config_reset(
    input wire clk,
    input wire [7:0] config_data,
    input wire config_valid,
    input wire reset_trigger,
    output reg [7:0] reset_out
);
    // 增加流水线阶段寄存器
    reg [7:0] config_reg_stage1;
    reg [7:0] config_reg_stage2;
    reg [7:0] config_reg_stage3;
    
    // 触发信号多级流水线
    reg reset_trigger_stage1;
    reg reset_trigger_stage2;
    reg reset_trigger_stage3;
    
    // 流水线阶段1 - 输入捕获
    always @(posedge clk) begin
        if (config_valid) begin
            config_reg_stage1 <= config_data;
        end
        reset_trigger_stage1 <= reset_trigger;
    end
    
    // 流水线阶段2 - 数据传播
    always @(posedge clk) begin
        config_reg_stage2 <= config_reg_stage1;
        reset_trigger_stage2 <= reset_trigger_stage1;
    end
    
    // 流水线阶段3 - 数据准备
    always @(posedge clk) begin
        config_reg_stage3 <= config_reg_stage2;
        reset_trigger_stage3 <= reset_trigger_stage2;
    end
    
    // 流水线阶段4 - 输出生成
    always @(posedge clk) begin
        reset_out <= reset_trigger_stage3 ? config_reg_stage3 : 8'h0;
    end
endmodule