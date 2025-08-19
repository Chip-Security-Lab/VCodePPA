//SystemVerilog
module Comparator_RegSync #(parameter WIDTH = 4) (
    input               clk,      // 全局时钟
    input               rst_n,    // 低有效同步复位
    input  [WIDTH-1:0]  in1,      // 输入向量1
    input  [WIDTH-1:0]  in2,      // 输入向量2
    output reg          eq_out    // 寄存后的比较结果
);

    // 流水线寄存器
    reg [WIDTH-1:0] in1_stage1, in2_stage1;
    reg [WIDTH-1:0] in1_stage2, in2_stage2;
    reg eq_stage1, eq_stage2;
    reg valid_stage1, valid_stage2;

    // 第一级流水线：输入寄存
    always @(posedge clk) begin
        if (!rst_n) begin
            in1_stage1 <= {WIDTH{1'b0}};
            in2_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            in1_stage1 <= in1;
            in2_stage1 <= in2;
            valid_stage1 <= 1'b1;
        end
    end

    // 第二级流水线：比较计算
    always @(posedge clk) begin
        if (!rst_n) begin
            in1_stage2 <= {WIDTH{1'b0}};
            in2_stage2 <= {WIDTH{1'b0}};
            eq_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            in1_stage2 <= in1_stage1;
            in2_stage2 <= in2_stage1;
            eq_stage1 <= (in1_stage1 == in2_stage1);
            valid_stage2 <= valid_stage1;
        end
    end

    // 第三级流水线：输出寄存
    always @(posedge clk) begin
        if (!rst_n) begin
            eq_out <= 1'b0;
        end else begin
            eq_out <= valid_stage2 ? eq_stage1 : 1'b0;
        end
    end

endmodule