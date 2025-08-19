//SystemVerilog
`timescale 1ns / 1ps
module nand2_18 (
    input  wire  clk,    // 系统时钟
    input  wire  rst_n,  // 低电平有效复位信号
    input  wire  A, B,   // 输入操作数
    output wire  Y       // NAND运算结果
);
    // 数据流水线阶段定义
    localparam PIPE_STAGES = 3;
    
    // 流水线寄存器
    reg [1:0] input_stage;     // 输入操作数缓存
    reg       logic_stage;     // 中间逻辑结果
    reg       output_stage;    // 输出结果缓存
    
    // 阶段1: 输入寄存 - 捕获输入操作数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_stage <= 2'b00;
        end else begin
            input_stage <= {A, B}; // 并行捕获输入信号
        end
    end
    
    // 阶段2: 逻辑操作 - 计算AND中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            logic_stage <= 1'b0;
        end else begin
            logic_stage <= input_stage[1] & input_stage[0]; // A & B
        end
    end
    
    // 阶段3: 输出形成 - 计算NAND结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_stage <= 1'b1; // NAND复位值为1
        end else begin
            output_stage <= ~logic_stage; // 取反操作
        end
    end
    
    // 连接输出寄存器到输出端口
    assign Y = output_stage;
    
endmodule