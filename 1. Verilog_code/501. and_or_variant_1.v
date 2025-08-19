module and_or (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 低电平有效复位
    input wire a, b, c, d,   // 输入信号
    output reg y             // 输出信号
);

    // 内部信号定义
    reg stage1_and;          // 第一级流水线 - AND结果
    reg stage1_or;           // 第一级流水线 - OR结果
    reg stage2_and_reg;      // 第二级流水线 - AND寄存器
    reg stage2_or_reg;       // 第二级流水线 - OR寄存器
    reg stage3_xor;          // 第三级流水线 - XOR结果
    reg stage4_output;       // 第四级流水线 - 输出寄存器

    // 第一级流水线 - 组合逻辑
    always @(*) begin
        stage1_and = a & b;
        stage1_or = c | d;
    end

    // 第二级流水线 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_reg <= 1'b0;
            stage2_or_reg <= 1'b0;
        end else begin
            stage2_and_reg <= stage1_and;
            stage2_or_reg <= stage1_or;
        end
    end

    // 第三级流水线 - 组合逻辑
    always @(*) begin
        stage3_xor = stage2_and_reg ^ stage2_or_reg;
    end

    // 第四级流水线 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_output <= 1'b0;
            y <= 1'b0;
        end else begin
            stage4_output <= stage3_xor;
            y <= stage4_output;
        end
    end

endmodule