//SystemVerilog
module ClockGatingBridge(
    input clk, rst_n,
    input activity,
    output gated_clk
);
    reg enable_latch;
    
    // 改进的时钟门控逻辑
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            enable_latch <= 1'b0;
        else
            enable_latch <= activity | enable_latch;
    end
    
    // 使用与门实现时钟门控
    assign gated_clk = clk & enable_latch;
endmodule