//SystemVerilog
`timescale 1ns / 1ps

module clk_gate_shift_en #(
    parameter DEPTH = 3
)(
    input  wire            clk,      // 系统时钟
    input  wire            en,       // 使能信号
    input  wire            in,       // 输入数据
    output reg [DEPTH-1:0] out       // 移位寄存器输出
);

    // 内部信号定义
    reg            clk_gated;        // 门控时钟
    wire           clk_en;           // 时钟使能
    reg [DEPTH-1:0] shift_reg;       // 优化后的移位寄存器

    // 实现门控时钟以降低功耗
    assign clk_en = en;
    
    // 锁存器风格的时钟门控
    always @(*) begin
        if (!clk)
            clk_gated = clk_en;
    end
    
    // 单级流水线优化设计
    always @(posedge clk) begin
        if (clk_gated) begin
            // 使用级联移位操作实现数据移位
            shift_reg <= {shift_reg[DEPTH-2:0], in};
            out <= {shift_reg[DEPTH-2:0], in};
        end
    end

endmodule