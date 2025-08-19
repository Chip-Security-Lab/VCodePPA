//SystemVerilog
module subtract_xnor_operator (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号（低电平有效）
    input wire [7:0] a,    // 输入操作数A
    input wire [7:0] b,    // 输入操作数B
    output reg [7:0] difference,    // 减法结果
    output reg [7:0] xnor_result    // 异或非结果
);

    // 内部流水线寄存器
    reg [7:0] a_reg, b_reg;            // 第一级流水线寄存器
    reg [7:0] diff_stage1;             // 减法中间结果
    reg [7:0] xnor_stage1;             // 异或非中间结果
    
    // 第一级流水线：输入寄存 - 操作数A
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h0;
        end else begin
            a_reg <= a;
        end
    end

    // 第一级流水线：输入寄存 - 操作数B
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_reg <= 8'h0;
        end else begin
            b_reg <= b;
        end
    end
    
    // 第二级流水线：减法运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_stage1 <= 8'h0;
        end else begin
            diff_stage1 <= a_reg - b_reg;
        end
    end

    // 第二级流水线：异或非运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_stage1 <= 8'h0;
        end else begin
            xnor_stage1 <= ~(a_reg ^ b_reg);
        end
    end
    
    // 第三级流水线：减法结果输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference <= 8'h0;
        end else begin
            difference <= diff_stage1;
        end
    end

    // 第三级流水线：异或非结果输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result <= 8'h0;
        end else begin
            xnor_result <= xnor_stage1;
        end
    end

endmodule