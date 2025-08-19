//SystemVerilog
// SystemVerilog
// 顶层模块
module nand2_15 (
    input  wire a_in,    // 输入信号A，重命名为更清晰的a_in
    input  wire b_in,    // 输入信号B，重命名为更清晰的b_in
    output wire y_out    // 输出信号Y，重命名为更清晰的y_out
);
    // 内部流水线寄存器
    reg a_stage1, b_stage1;    // 第一级流水线寄存器
    
    // 时钟和复位信号（增加时钟以支持流水线结构）
    wire clk;
    wire rst_n;
    
    // 时钟生成（对于仿真目的）
    `ifdef SIMULATION
    reg clk_gen = 0;
    initial begin
        forever #5 clk_gen = ~clk_gen;
    end
    assign clk = clk_gen;
    `endif
    
    // 流水线寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a_in;    // 捕获输入a到第一级流水线
            b_stage1 <= b_in;    // 捕获输入b到第一级流水线
        end
    end
    
    // 实例化优化的NAND数据路径
    nand_datapath nand_core (
        .clk(clk),
        .rst_n(rst_n),
        .a_stage1(a_stage1),
        .b_stage1(b_stage1),
        .result(y_out)
    );
    
endmodule

// 优化的NAND数据路径模块
module nand_datapath (
    input  wire clk,         // 时钟信号
    input  wire rst_n,       // 复位信号，低电平有效
    input  wire a_stage1,    // 来自第一级流水线的A信号
    input  wire b_stage1,    // 来自第一级流水线的B信号
    output wire result       // 结果输出
);
    // 内部信号定义
    wire and_result;         // AND操作的中间结果
    reg  nand_stage2;        // 第二级流水线寄存器
    
    // 第一级数据路径：计算AND结果
    assign and_result = a_stage1 & b_stage1;
    
    // 第二级流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_stage2 <= 1'b1;  // NAND的默认值为1
        end else begin
            nand_stage2 <= ~and_result;  // 存储NAND结果到第二级流水线
        end
    end
    
    // 最终结果输出
    assign result = nand_stage2;
    
    // 性能改进属性声明（用于综合工具指导）
    (* dont_touch = "true" *)
    (* max_fanout = "10" *)
    wire performance_critical = result;
    
endmodule