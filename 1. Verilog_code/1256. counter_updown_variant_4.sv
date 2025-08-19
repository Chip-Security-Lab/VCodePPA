//SystemVerilog
module counter_updown #(parameter WIDTH=4) (
    input clk, rst, dir, en,
    output reg [WIDTH-1:0] cnt
);
    
    // 移动寄存器，将控制信号在时钟沿上采样
    reg rst_reg, en_reg, dir_reg;
    
    always @(posedge clk) begin
        rst_reg <= rst;
        en_reg <= en;
        dir_reg <= dir;
    end
    
    // 使用已寄存的控制信号进行计数逻辑
    always @(posedge clk) begin
        if (rst_reg)
            cnt <= 0;
        else if (en_reg)
            cnt <= dir_reg ? cnt + 1 : cnt - 1;
    end
    
endmodule