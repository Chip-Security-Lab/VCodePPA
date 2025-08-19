//SystemVerilog
module cascaded_reset_dist(
    input wire clk,
    input wire rst_in,
    output wire [3:0] rst_cascade
);
    reg rst_in_reg;
    reg [2:0] rst_shift;

    // 首先对输入信号进行寄存
    always @(posedge clk) begin
        rst_in_reg <= rst_in;
    end

    // 使用条件运算符代替if-else进行级联移位操作
    always @(posedge clk) begin
        rst_shift <= rst_in_reg ? 3'b111 : {1'b0, rst_shift[2:1]};
    end

    // 构建输出信号
    assign rst_cascade = {rst_shift, rst_in_reg};
endmodule