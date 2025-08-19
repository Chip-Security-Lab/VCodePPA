//SystemVerilog
// 流水线化的寄存器输出比较器
module Comparator_RegSync #(parameter WIDTH = 4) (
    input               clk,      // 全局时钟
    input               rst_n,    // 低有效同步复位
    input               valid_in, // 输入有效信号
    input  [WIDTH-1:0]  in1,      // 输入向量1
    input  [WIDTH-1:0]  in2,      // 输入向量2
    output reg          valid_out,// 输出有效信号
    output reg          eq_out    // 寄存后的比较结果
);
    // 流水线阶段1: 比较阶段
    reg [WIDTH-1:0] in1_stage1;
    reg [WIDTH-1:0] in2_stage1;
    reg             valid_stage1;
    reg             comp_result_stage1;
    
    // 流水线阶段2: 处理阶段
    reg             valid_stage2;
    reg             comp_result_stage2;
    
    // 流水线阶段1逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            in1_stage1 <= {WIDTH{1'b0}};
            in2_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            comp_result_stage1 <= 1'b0;
        end
        else begin
            in1_stage1 <= in1;
            in2_stage1 <= in2;
            valid_stage1 <= valid_in;
            comp_result_stage1 <= (in1 == in2);
        end
    end
    
    // 流水线阶段2逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            comp_result_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            comp_result_stage2 <= comp_result_stage1;
        end
    end
    
    // 输出阶段
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            eq_out <= 1'b0;
        end
        else begin
            valid_out <= valid_stage2;
            eq_out <= comp_result_stage2;
        end
    end
endmodule