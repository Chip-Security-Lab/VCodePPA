//SystemVerilog
module or_gate_2input_4bit (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号，低电平有效
    input wire [3:0] a,      // 输入数据a
    input wire [3:0] b,      // 输入数据b
    input wire data_valid,   // 数据有效信号
    output reg [3:0] y,      // 输出结果
    output reg result_valid  // 结果有效信号
);

    // 内部流水线寄存器
    reg [3:0] a_reg, b_reg;
    reg [3:0] or_result;
    reg valid_stage1, valid_stage2;

    // 第一级流水线：输入寄存器 - 重置逻辑
    always @(negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            valid_stage1 <= 1'b0;
        end
    end

    // 第一级流水线：输入寄存器 - 时钟逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            a_reg <= a;
            b_reg <= b;
            valid_stage1 <= data_valid;
        end
    end

    // 第二级流水线：执行OR运算 - 重置逻辑
    always @(negedge rst_n) begin
        if (!rst_n) begin
            or_result <= 4'b0;
            valid_stage2 <= 1'b0;
        end
    end

    // 第二级流水线：执行OR运算 - 时钟逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            or_result <= a_reg | b_reg;
            valid_stage2 <= valid_stage1;
        end
    end

    // 第三级流水线：输出寄存器 - 重置逻辑
    always @(negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'b0;
            result_valid <= 1'b0;
        end
    end

    // 第三级流水线：输出寄存器 - 时钟逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            y <= or_result;
            result_valid <= valid_stage2;
        end
    end

endmodule