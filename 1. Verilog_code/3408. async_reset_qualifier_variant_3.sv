//SystemVerilog
module async_reset_qualifier (
    input  wire       clk,             // 系统时钟
    input  wire       raw_reset,       // 原始复位信号
    input  wire [3:0] qualifiers,      // 复位限定条件
    output wire [3:0] qualified_resets // 输出的限定复位信号
);
    // 中间寄存器，用于分割数据路径
    reg        raw_reset_stage1;
    reg        raw_reset_stage2;
    reg [3:0]  qualifiers_stage1;
    reg [3:0]  qualifiers_stage2;
    
    // 流水线阶段1：捕获输入信号
    always @(posedge clk or posedge raw_reset) begin
        if (raw_reset) begin
            raw_reset_stage1 <= 1'b1;
            qualifiers_stage1 <= 4'b0000;
        end else begin
            raw_reset_stage1 <= raw_reset;
            qualifiers_stage1 <= qualifiers;
        end
    end
    
    // 流水线阶段2：信号处理
    always @(posedge clk or posedge raw_reset) begin
        if (raw_reset) begin
            raw_reset_stage2 <= 1'b1;
            qualifiers_stage2 <= 4'b0000;
        end else begin
            raw_reset_stage2 <= raw_reset_stage1;
            qualifiers_stage2 <= qualifiers_stage1;
        end
    end
    
    // 最终复位信号生成 - 通过流水线寄存器后的信号计算
    wire [3:0] reset_vector = {4{raw_reset_stage2}};
    assign qualified_resets = reset_vector & qualifiers_stage2;

endmodule