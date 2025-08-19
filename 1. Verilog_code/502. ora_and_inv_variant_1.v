module ora_and_inv(
    input  wire clk,          // 时钟信号
    input  wire rst_n,        // 异步复位信号
    input  wire a,            // 输入信号a
    input  wire b,            // 输入信号b
    input  wire c,            // 输入信号c
    output reg  y             // 输出信号y
);

    // 流水线寄存器定义
    reg stage1_or_reg;        // 第一级流水线寄存器
    reg stage2_not_reg;       // 第二级流水线寄存器
    reg stage3_and_reg;       // 第三级流水线寄存器

    // 组合逻辑中间信号
    wire stage1_or_out;       // OR操作输出
    wire stage2_not_out;      // NOT操作输出
    wire stage3_and_out;      // AND操作输出

    // 数据通路阶段1: OR操作
    assign stage1_or_out = a | b;

    // 数据通路阶段2: NOT操作
    assign stage2_not_out = ~c;

    // 数据通路阶段3: AND操作
    assign stage3_and_out = stage1_or_reg & stage2_not_reg;

    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_or_reg  <= 1'b0;
            stage2_not_reg <= 1'b0;
            stage3_and_reg <= 1'b0;
            y             <= 1'b0;
        end else begin
            stage1_or_reg  <= stage1_or_out;
            stage2_not_reg <= stage2_not_out;
            stage3_and_reg <= stage3_and_out;
            y             <= stage3_and_reg;
        end
    end

endmodule