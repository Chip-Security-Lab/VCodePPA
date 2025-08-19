//SystemVerilog
module Sync_XNOR(
    input wire clk,
    input wire [7:0] sig_a, sig_b,
    output reg [7:0] q
);
    // 优化中间信号表示
    wire [7:0] xnor_result;
    
    // 优化直接使用位等价运算，减少逻辑门数量
    assign xnor_result = ~(sig_a ^ sig_b);
    
    // 时序逻辑优化
    always @(posedge clk) begin
        q <= xnor_result;
    end
endmodule