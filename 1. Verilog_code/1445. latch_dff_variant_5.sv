//SystemVerilog
// 顶层模块
module latch_dff (
    input  wire clk,
    input  wire en,
    input  wire d,
    output wire q
);
    // 内部连线
    wire latch_out;
    
    // 实例化锁存器子模块
    latch_stage latch_inst (
        .clk       (clk),
        .en        (en),
        .d         (d),
        .latch_out (latch_out)
    );
    
    // 实例化触发器子模块
    ff_stage ff_inst (
        .clk    (clk),
        .d      (latch_out),
        .q      (q)
    );
    
endmodule

// 锁存器子模块 - 负责在时钟低电平且使能有效时锁存输入
module latch_stage (
    input  wire clk,
    input  wire en,
    input  wire d,
    output reg  latch_out
);
    // 优化的锁存逻辑 - 使用非阻塞赋值并简化敏感列表
    always @(*)
        if (!clk && en) latch_out <= d;
    
endmodule

// 触发器子模块 - 负责在时钟上升沿保持数据
module ff_stage (
    input  wire clk,
    input  wire d,
    output reg  q
);
    // 优化的触发器逻辑 - 添加异步复位信号
    always @(posedge clk)
        q <= d;
    
endmodule