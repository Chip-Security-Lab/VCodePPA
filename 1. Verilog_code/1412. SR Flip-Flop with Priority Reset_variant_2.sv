//SystemVerilog
module sr_ff_priority_reset (
    input wire clk,
    input wire s,
    input wire r,
    output reg q
);
    // 将输出q逻辑移到时序块中，消除组合逻辑环路
    // 这样可以改善时序性能并降低功耗
    always @(posedge clk) begin
        if (r)         // Reset优先
            q <= 1'b0;
        else if (s)    // Set操作
            q <= 1'b1;
        // 否则保持当前状态
    end
endmodule