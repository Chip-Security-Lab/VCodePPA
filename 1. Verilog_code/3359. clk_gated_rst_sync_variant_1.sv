//SystemVerilog
module clk_gated_rst_sync (
    input  wire clk,
    input  wire clk_en,
    input  wire async_rst_n,
    output wire sync_rst_n
);
    reg  [1:0] sync_stages;
    wire       gated_clk;
    
    // 优化的时钟门控电路，使用latch防止毛刺
    reg  clk_en_latch;
    
    always @(*) begin
        if (clk == 1'b0)
            clk_en_latch = clk_en;
    end
    
    // 使用与门实现时钟门控
    assign gated_clk = clk & clk_en_latch;
    
    // 优化的两级同步器结构
    always @(posedge gated_clk or negedge async_rst_n) begin
        if (async_rst_n == 1'b0)
            sync_stages <= 2'b00;
        else
            sync_stages <= {sync_stages[0], 1'b1};
    end
    
    // 输出最终同步的复位信号
    assign sync_rst_n = sync_stages[1];
endmodule