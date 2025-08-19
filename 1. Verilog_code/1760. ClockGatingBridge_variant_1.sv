//SystemVerilog
module ClockGatingBridge(
    input clk, rst_n,
    input activity,
    output gated_clk
);
    reg enable_latch;
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            enable_latch <= 1'b0;
        else
            enable_latch <= activity | enable_latch;
    end
    
    assign gated_clk = clk & enable_latch;
endmodule