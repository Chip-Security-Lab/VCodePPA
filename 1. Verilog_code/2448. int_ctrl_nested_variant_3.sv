//SystemVerilog
module int_ctrl_edge_detect #(
    parameter WIDTH = 8
)(
    input                  clk,
    input  [WIDTH-1:0]     async_int,
    output [WIDTH-1:0]     edge_out
);
    // -------------------------------------------------
    // 双级同步器 - 处理异步输入信号，减少跨时钟域问题
    // -------------------------------------------------
    (* async_reg = "true" *) reg [WIDTH-1:0] sync_stage1_reg;
    (* async_reg = "true" *) reg [WIDTH-1:0] sync_stage2_reg;
    reg [WIDTH-1:0] prev_sync_reg;
    
    // 分离同步逻辑，减少关键路径
    always @(posedge clk) begin
        sync_stage1_reg <= async_int;
        sync_stage2_reg <= sync_stage1_reg;
    end
    
    // 单独的前一状态寄存
    always @(posedge clk) begin
        prev_sync_reg <= sync_stage2_reg;
    end
    
    // -------------------------------------------------
    // 优化的边缘检测逻辑 - 通过展开和直接赋值减少关键路径
    // -------------------------------------------------
    // 使用连续赋值而非generate循环，减少逻辑层级
    assign edge_out = sync_stage2_reg & ~prev_sync_reg;

endmodule