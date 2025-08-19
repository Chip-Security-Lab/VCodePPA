//SystemVerilog
module counter_step #(
    parameter WIDTH = 4,
    parameter STEP = 2
)(
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] cnt
);

    // 优化计数器逻辑，使用条件运算符替代if-else结构
    always @(posedge clk or negedge rst_n)
        cnt <= (!rst_n) ? {WIDTH{1'b0}} : cnt + STEP;

endmodule