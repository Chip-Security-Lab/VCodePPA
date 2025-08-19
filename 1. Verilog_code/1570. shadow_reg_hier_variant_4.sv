//SystemVerilog
module shadow_reg_hier #(parameter DW=16) (
    input clk, 
    input rst_n,  // 添加复位信号
    input main_en, 
    input sub_en,
    input [DW-1:0] main_data,
    input data_valid_in,  // 数据有效输入信号
    output reg data_valid_out, // 数据有效输出信号
    output reg [DW-1:0] final_data
);
    // 流水线阶段信号
    reg [DW-1:0] stage1_data;
    reg [DW-1:0] stage2_data;
    reg [DW-1:0] stage3_data;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    reg main_en_stage1;
    reg sub_en_stage1;
    reg sub_en_stage2;
    
    // 流水线第一级 - 数据和控制信号寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
            main_en_stage1 <= 1'b0;
            sub_en_stage1 <= 1'b0;
        end else begin
            stage1_data <= main_data;
            valid_stage1 <= data_valid_in;
            main_en_stage1 <= main_en;
            sub_en_stage1 <= sub_en;
        end
    end
    
    // 流水线第二级 - 主数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
            sub_en_stage2 <= 1'b0;
        end else begin
            if (main_en_stage1 && valid_stage1) begin
                stage2_data <= stage1_data; // 处理主数据
            end
            valid_stage2 <= valid_stage1;
            sub_en_stage2 <= sub_en_stage1;
        end
    end
    
    // 流水线第三级 - 影子寄存器处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            if (sub_en_stage2 && valid_stage2) begin
                stage3_data <= stage2_data; // 影子寄存器处理
            end
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出寄存器 - 最终数据输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_data <= {DW{1'b0}};
            data_valid_out <= 1'b0;
        end else begin
            final_data <= stage3_data;
            data_valid_out <= valid_stage3;
        end
    end
endmodule