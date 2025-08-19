//SystemVerilog
//===================================================================
//===================================================================
// 顶层模块 - 将复杂逻辑路径分解为清晰的流水线结构
//===================================================================
module nand_or_xnor_gate (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 复位信号，低电平有效
    input  wire        A,        // 输入信号A
    input  wire        B,        // 输入信号B
    input  wire        C,        // 输入信号C
    output wire        Y         // 输出信号Y
);

    // 内部信号定义 - 分解数据路径
    wire        nand_result;     // NAND运算结果
    wire        xnor_result;     // XNOR运算结果
    
    // 寄存器信号 - 用于流水线处理
    reg         nand_stage;      // NAND运算结果寄存器
    reg         xnor_stage;      // XNOR运算结果寄存器
    reg         output_stage;    // 输出结果寄存器

    // 第一阶段 - 计算基本逻辑运算
    assign nand_result = ~(A & B);  // NAND运算
    assign xnor_result = (C ~^ A);  // XNOR运算

    // 流水线处理 - 三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            nand_stage   <= 1'b0;
            xnor_stage   <= 1'b0;
            output_stage <= 1'b0;
        end else begin
            // 第一级流水线 - 捕获基本逻辑结果
            nand_stage   <= nand_result;
            xnor_stage   <= xnor_result;
            
            // 第二级流水线 - 计算最终结果
            output_stage <= nand_stage | xnor_stage;
        end
    end

    // 输出赋值
    assign Y = output_stage;

endmodule