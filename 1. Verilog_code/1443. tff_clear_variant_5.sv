//SystemVerilog
// 使用IEEE 1364-2005 Verilog标准
module tff_clear (
    input clk, clr,
    output reg q
);
    // 增加中间信号以实现后向重定时
    reg next_q;
    
    // 计算下一状态逻辑
    always @(posedge clk) begin
        if (clr) begin
            next_q <= 1'b0;
        end else begin
            next_q <= ~q;
        end
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        q <= next_q;
    end
endmodule