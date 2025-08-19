//SystemVerilog
// 顶层模块
module d_flip_flop (
    input  wire clk,
    input  wire d,
    output wire q
);
    // 增加了多级流水线存储信号
    wire data_stage1;
    wire data_stage2;
    wire data_stage3;
    
    // 第一级流水线寄存
    data_buffer stage1_buffer (
        .clk_in     (clk),
        .data_in    (d),
        .data_out   (data_stage1)
    );
    
    // 第二级流水线寄存
    data_buffer stage2_buffer (
        .clk_in     (clk),
        .data_in    (data_stage1),
        .data_out   (data_stage2)
    );
    
    // 第三级流水线寄存（最终状态存储）
    state_storage state_storage_inst (
        .clk_in     (clk),
        .state_in   (data_stage2),
        .state_out  (q)
    );
    
endmodule

// 中间数据缓冲模块 - 优化路径延迟
module data_buffer (
    input  wire clk_in,
    input  wire data_in,
    output reg  data_out
);
    // 时序逻辑：在时钟上升沿缓存数据
    always @(posedge clk_in) begin
        data_out <= data_in;
    end
    
endmodule

// 状态存储模块 - 优化时序性能
module state_storage (
    input  wire clk_in,
    input  wire state_in,
    output reg  state_out
);
    // 时序逻辑：在时钟上升沿存储状态
    // 实现非阻塞赋值以避免竞争条件
    always @(posedge clk_in) begin
        state_out <= state_in;
    end
    
endmodule