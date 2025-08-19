//SystemVerilog (IEEE 1364-2005)
`timescale 1ns / 1ps

// 顶层模块
module latch_dff (
    input  wire clk,
    input  wire en,
    input  wire d,
    output wire q
);

    // 内部连线
    wire d_reg;
    
    // 输入寄存器化 - 将后端寄存器向前移动
    reg d_input_reg;
    
    always @(posedge clk) begin
        d_input_reg <= d;
    end
    
    // 实例化优化后的透明锁存器子模块
    transparent_latch u_latch (
        .en        (en),
        .clk       (clk),
        .d         (d_input_reg),
        .latch_out (d_reg)
    );
    
    // 实例化优化后的D触发器子模块
    d_flip_flop u_dff (
        .clk    (clk),
        .d      (d_reg),
        .q      (q)
    );

endmodule

// 透明锁存器子模块 - 优化后的锁存器逻辑
module transparent_latch (
    input  wire en,
    input  wire clk,
    input  wire d,
    output wire latch_out
);

    // 锁存器逻辑现在使用组合逻辑实现，移除了内部寄存器
    assign latch_out = (en && !clk) ? d : 1'bz;

endmodule

// D触发器子模块
module d_flip_flop (
    input  wire clk,
    input  wire d,
    output reg  q
);

    // 在时钟上升沿捕获输入数据
    always @(posedge clk) begin
        q <= d;
    end

endmodule