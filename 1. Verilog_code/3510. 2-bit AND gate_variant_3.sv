//SystemVerilog
// 重组后的顶层模块 - 添加了流水线结构
module and_gate_2bit (
    input wire clk,             // 时钟信号
    input wire rst_n,           // 复位信号，低电平有效
    input wire [1:0] a,         // 2-bit输入A
    input wire [1:0] b,         // 2-bit输入B
    output reg [1:0] y          // 2-bit输出Y，改为寄存器输出
);
    // 内部流水线阶段信号
    reg [1:0] a_stage1, b_stage1;
    wire [1:0] y_comb;
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 2'b0;
            b_stage1 <= 2'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    // 并行的AND运算数据路径
    and_datapath and_dp (
        .a(a_stage1),
        .b(b_stage1),
        .y(y_comb)
    );
    
    // 输出寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 2'b0;
        end else begin
            y <= y_comb;
        end
    end
endmodule

// 优化的数据通路模块
module and_datapath (
    input wire [1:0] a,
    input wire [1:0] b,
    output wire [1:0] y
);
    // 位宽参数化，方便未来扩展
    parameter WIDTH = 2;
    parameter GATE_DELAY = 1;
    
    // 生成多位并行AND逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : and_bit
            // 优化的AND单元，减少逻辑深度
            and_cell #(
                .GATE_DELAY(GATE_DELAY)
            ) and_unit (
                .a(a[i]),
                .b(b[i]),
                .y(y[i])
            );
        end
    endgenerate
endmodule

// 基本AND运算单元
module and_cell (
    input wire a,
    input wire b,
    output wire y
);
    // 参数化门延迟，便于时序优化
    parameter GATE_DELAY = 1;
    
    // 基本AND运算，保持原有延迟特性
    assign #(GATE_DELAY) y = a & b;
endmodule