//SystemVerilog
module srff_safe (
    input clk, s, r,
    output reg q
);
    // 将寄存器前移，直接在时钟边沿处理组合逻辑
    always @(posedge clk) begin
        if (s && r) q <= 1'bx;      // 非法状态处理
        else if (s) q <= 1'b1;
        else if (r) q <= 1'b0;
        else q <= q;
    end
endmodule