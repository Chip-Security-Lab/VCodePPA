module ClockGatingBridge(
    input clk, rst_n,
    input activity,
    output gated_clk
);
    reg enable_latch;
    
    // 使用合适的时钟门控技术
    always @(clk or activity) begin
        if (!clk)
            enable_latch <= activity | enable_latch;
    end
    
    // 使用AND门进行时钟门控
    assign gated_clk = clk & enable_latch;
endmodule