//SystemVerilog
module reg_config_reset(
    input wire clk,
    input wire rst_n,  // 添加异步复位信号
    input wire [7:0] config_data,
    input wire config_valid,
    input wire reset_trigger,
    output reg [7:0] reset_out,
    output reg output_valid  // 添加输出有效信号
);
    // 流水线寄存器
    reg [7:0] config_reg_stage1;
    reg [7:0] config_reg_stage2;
    reg reset_trigger_stage1;
    reg reset_trigger_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // 第一级流水线 - 配置数据寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg_stage1 <= 8'h0;
            reset_trigger_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (config_valid)
                config_reg_stage1 <= config_data;
            reset_trigger_stage1 <= reset_trigger;
            valid_stage1 <= config_valid || reset_trigger;
        end
    end
    
    // 第二级流水线 - 数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg_stage2 <= 8'h0;
            reset_trigger_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            config_reg_stage2 <= config_reg_stage1;
            reset_trigger_stage2 <= reset_trigger_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 输出计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_out <= 8'h0;
            output_valid <= 1'b0;
        end else begin
            reset_out <= reset_trigger_stage2 ? config_reg_stage2 : 8'h0;
            output_valid <= valid_stage2;
        end
    end
endmodule