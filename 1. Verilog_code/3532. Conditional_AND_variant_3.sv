//SystemVerilog
module Conditional_AND(
    input wire clk,          // 时钟输入
    input wire rst_n,        // 复位信号
    input wire sel,          // 选择信号
    input wire [7:0] op_a, op_b,  // 操作数输入
    output reg [7:0] res     // 结果输出
);
    // 内部流水线寄存器 - 阶段1
    reg sel_stage1;
    reg [7:0] op_a_stage1, op_b_stage1;
    
    // 内部流水线寄存器 - 阶段2
    reg sel_stage2;
    reg [7:0] op_a_stage2, op_b_stage2;
    
    // 内部流水线寄存器 - 阶段3
    reg sel_stage3;
    reg [3:0] and_result_lower;
    reg [3:0] and_result_upper;
    
    // 内部流水线寄存器 - 阶段4
    reg sel_stage4;
    reg [7:0] and_result_stage4;
    
    // 阶段1: 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage1 <= 1'b0;
            op_a_stage1 <= 8'h00;
            op_b_stage1 <= 8'h00;
        end else begin
            sel_stage1 <= sel;
            op_a_stage1 <= op_a;
            op_b_stage1 <= op_b;
        end
    end
    
    // 阶段2: 输入二级寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage2 <= 1'b0;
            op_a_stage2 <= 8'h00;
            op_b_stage2 <= 8'h00;
        end else begin
            sel_stage2 <= sel_stage1;
            op_a_stage2 <= op_a_stage1;
            op_b_stage2 <= op_b_stage1;
        end
    end
    
    // 阶段3: 分段计算AND操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage3 <= 1'b0;
            and_result_lower <= 4'h0;
            and_result_upper <= 4'h0;
        end else begin
            sel_stage3 <= sel_stage2;
            and_result_lower <= op_a_stage2[3:0] & op_b_stage2[3:0];
            and_result_upper <= op_a_stage2[7:4] & op_b_stage2[7:4];
        end
    end
    
    // 阶段4: 合并AND结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage4 <= 1'b0;
            and_result_stage4 <= 8'h00;
        end else begin
            sel_stage4 <= sel_stage3;
            and_result_stage4 <= {and_result_upper, and_result_lower};
        end
    end
    
    // 阶段5: 输出选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'h00;
        end else begin
            res <= sel_stage4 ? and_result_stage4 : 8'hFF;
        end
    end

endmodule