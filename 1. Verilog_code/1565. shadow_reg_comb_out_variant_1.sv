//SystemVerilog
module shadow_reg_comb_out #(parameter WIDTH=8) (
    input clk, en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] shadow_reg;
    wire [WIDTH-1:0] neg_din; // 新增信号，用于存储din的补码
    wire [WIDTH-1:0] result;  // 新增信号，用于存储加法结果

    assign neg_din = ~din + 1'b1; // 计算din的补码

    always @(posedge clk) begin
        if(en) shadow_reg <= shadow_reg + neg_din; // 使用补码加法实现减法
    end

    assign dout = shadow_reg;
endmodule