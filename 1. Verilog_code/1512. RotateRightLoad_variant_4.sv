//SystemVerilog
// IEEE 1364-2005 Verilog标准
module RotateRightLoad #(
    parameter DATA_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire load_en,
    input wire data_valid_in,
    input wire [DATA_WIDTH-1:0] parallel_in,
    output wire [DATA_WIDTH-1:0] data_out,
    output wire data_valid_out
);

    // 流水线寄存器 - 第一级
    reg [DATA_WIDTH-1:0] data_stage1;
    reg valid_stage1;
    wire [DATA_WIDTH-1:0] rotated_data;
    
    // 流水线寄存器 - 第二级
    reg [DATA_WIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    // 条件反相减法器实现旋转 (替代原始旋转逻辑)
    wire [DATA_WIDTH-1:0] inverted_data;
    wire [DATA_WIDTH-1:0] operand_a, operand_b;
    wire subtract_control;
    wire carry_out;
    
    // 控制信号决定是否需要反相
    assign subtract_control = data_stage1[0];
    
    // 基于控制信号条件反相
    assign operand_a = {data_stage1[DATA_WIDTH-1:1], 1'b0};
    assign operand_b = subtract_control ? ~{DATA_WIDTH{1'b0}} : {DATA_WIDTH{1'b0}};
    
    // 条件反相减法器实现
    assign {carry_out, inverted_data} = operand_a + operand_b + subtract_control;
    
    // 最终旋转结果
    assign rotated_data = {data_stage1[0], inverted_data[DATA_WIDTH-1:1]};
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            if (data_valid_in) begin
                data_stage1 <= load_en ? parallel_in : rotated_data;
                valid_stage1 <= 1'b1;
            end else if (valid_stage2) begin
                // 无新数据输入时继续处理
                data_stage1 <= rotated_data;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign data_out = data_stage2;
    assign data_valid_out = valid_stage2;

endmodule