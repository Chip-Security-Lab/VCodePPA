//SystemVerilog
//IEEE 1364-2005 Verilog

// 顶层模块
module and_not_gate (
    input  wire clk,     // 时钟输入
    input  wire rst_n,   // 复位信号，低电平有效
    input  wire A, B,    // 数据输入A, B
    output wire Y        // 数据输出Y
);
    // 数据流水线寄存器
    reg stage1_A, stage1_B;  // 第一级流水线寄存器
    reg stage1_and_result;   // 与运算结果寄存器
    reg stage1_not_result;   // 非运算结果寄存器
    reg stage2_Y;            // 最终结果寄存器

    // 数据流第一级：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
        end
    end

    // 数据流第二级：基本逻辑计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_and_result <= 1'b0;
            stage1_not_result <= 1'b0;
        end else begin
            stage1_and_result <= stage1_A & stage1_B;  // 与门运算
            stage1_not_result <= ~stage1_A;            // 非门运算
        end
    end

    // 数据流第三级：最终逻辑计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_Y <= 1'b0;
        end else begin
            stage2_Y <= stage1_and_result & stage1_not_result;  // 最终与门运算
        end
    end

    // 输出赋值
    assign Y = stage2_Y;

endmodule