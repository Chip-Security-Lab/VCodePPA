module latch_dff (
    input clk, en,
    input d,
    output reg q
);
always @(*) if (en && !clk) q = d; // 锁存阶段
always @(posedge clk) q <= q;     // 触发保持
endmodule