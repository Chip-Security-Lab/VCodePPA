//SystemVerilog
module dual_clock_gate (
    input  wire fast_clk,
    input  wire slow_clk,
    input  wire sel,
    output reg  gated_clk
);
    // 使用always块和if-else结构实现时钟选择
    always @(fast_clk or slow_clk or sel) begin
        if (sel) begin
            gated_clk = slow_clk;
        end else begin
            gated_clk = fast_clk;
        end
    end
endmodule