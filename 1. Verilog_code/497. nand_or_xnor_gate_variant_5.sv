//SystemVerilog
module nand_or_xnor_gate (
    input  wire clk,      // 时钟信号
    input  wire rst_n,    // 复位信号
    input  wire A, B, C,  // 输入A, B, C
    output reg  Y         // 输出Y
);
    // 内部信号定义
    reg A_reg, B_reg, C_reg;       // 寄存输入信号
    
    // 将靠近输出的寄存器移动到组合逻辑之前
    reg A_reg2, B_reg2, C_reg2;    // 第二级输入寄存
    reg stage1_nand, stage1_xnor;  // 拆分流水线结果
    
    // 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 1'b0;
            B_reg <= 1'b0;
            C_reg <= 1'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
            C_reg <= C;
        end
    end
    
    // 第二级输入寄存 - 复制寄存器以保持路径独立性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg2 <= 1'b0;
            B_reg2 <= 1'b0;
            C_reg2 <= 1'b0;
        end else begin
            A_reg2 <= A_reg;
            B_reg2 <= B_reg;
            C_reg2 <= C_reg;
        end
    end
    
    // 将组合逻辑结果分别寄存 - 后向重定时
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_nand <= 1'b0;
            stage1_xnor <= 1'b0;
        end else begin
            stage1_nand <= ~(A_reg2 & B_reg2);  // NAND操作直接寄存
            stage1_xnor <= ~(A_reg2 ^ C_reg2);  // XNOR操作直接寄存
        end
    end
    
    // 输出寄存器 - 现在只执行OR操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage1_nand | stage1_xnor;  // 或操作
        end
    end

endmodule