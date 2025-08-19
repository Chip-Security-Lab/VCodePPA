//SystemVerilog
module multi_level_rst_sync #(
    parameter SYNC_STAGES = 2
)(
    input  wire clock,
    input  wire hard_rst_n,
    input  wire soft_rst_n,
    output wire system_rst_n,
    output wire periph_rst_n
);
    // 硬复位同步器 - 使用更有效的位宽声明
    reg [SYNC_STAGES-1:0] hard_rst_sync;
    
    // 软复位同步器 - 使用更有效的位宽声明
    reg [SYNC_STAGES-1:0] soft_rst_sync;
    
    // 硬复位同步逻辑 - 使用向量赋值优化复位路径
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n)
            hard_rst_sync <= '0;  // 使用SystemVerilog的默认值赋值
        else
            hard_rst_sync <= {hard_rst_sync[SYNC_STAGES-2:0], 1'b1};
    end
    
    // 使用独立的内部复位信号，减少扇出负载
    wire hard_rst_internal = hard_rst_sync[SYNC_STAGES-1];
    
    // 软复位同步逻辑 - 优化复位条件逻辑
    always @(posedge clock) begin
        if (!hard_rst_internal || !soft_rst_n)  // 改善时序路径，移除异步复位
            soft_rst_sync <= '0;
        else
            soft_rst_sync <= {soft_rst_sync[SYNC_STAGES-2:0], 1'b1};
    end
    
    // 增加同步输出缓冲器，减少关键路径扇出
    assign system_rst_n = hard_rst_internal;
    assign periph_rst_n = soft_rst_sync[SYNC_STAGES-1];

endmodule