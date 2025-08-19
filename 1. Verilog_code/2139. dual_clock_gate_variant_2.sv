//SystemVerilog
module dual_clock_gate (
    input  wire fast_clk,      // 快时钟输入
    input  wire slow_clk,      // 慢时钟输入
    input  wire sel,           // 时钟选择信号
    output wire gated_clk      // 输出门控时钟
);
    // 定义时钟路径寄存器和内部信号
    reg  sel_sync_fast1, sel_sync_fast2;    // 同步到快时钟域的选择信号，双FF同步
    reg  sel_sync_slow1, sel_sync_slow2;    // 同步到慢时钟域的选择信号，双FF同步
    
    wire fast_enable, slow_enable;          // 时钟使能信号
    wire fast_clock_path, slow_clock_path;  // 时钟通路
    
    // 合并相同触发条件的always块
    always @(posedge fast_clk) begin
        sel_sync_fast1 <= sel;
        sel_sync_fast2 <= sel_sync_fast1;
    end
    
    always @(posedge slow_clk) begin
        sel_sync_slow1 <= sel;
        sel_sync_slow2 <= sel_sync_slow1;
    end
    
    // 提前计算使能信号以减少关键路径延迟
    assign fast_enable = ~sel_sync_fast2;
    assign slow_enable = sel_sync_slow2;
    
    // 使用时钟门控单元实现，减少动态功耗
    assign fast_clock_path = fast_clk & fast_enable;
    assign slow_clock_path = slow_clk & slow_enable;
    
    // 使用OR门组合时钟路径
    assign gated_clk = fast_clock_path | slow_clock_path;

endmodule