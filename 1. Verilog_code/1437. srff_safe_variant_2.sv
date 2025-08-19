//SystemVerilog
module srff_safe (
    input wire clk, s, r,
    output reg q
);

reg s_reg, r_reg;
wire next_q;

// 将输入寄存器向前推移
always @(posedge clk) begin
    s_reg <= s;
    r_reg <= r;
end

// 组合逻辑决定下一状态
assign next_q = (s_reg && r_reg) ? 1'bx :
                (s_reg && !r_reg) ? 1'b1 :
                (!s_reg && r_reg) ? 1'b0 : q;

// 输出寄存器
always @(posedge clk) begin
    q <= next_q;
end

endmodule