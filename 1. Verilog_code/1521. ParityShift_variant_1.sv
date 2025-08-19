//SystemVerilog
// IEEE 1364-2005
module ParityShift #(parameter DATA_BITS=7) (
    input clk, rst, sin,
    output reg [DATA_BITS:0] sreg // [7:0] for 7+1 parity
);
    // 输入寄存器 - 将输入信号sin寄存一拍
    reg sin_reg;
    
    // 输入侧寄存，减少输入到第一级寄存器的延迟
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sin_reg <= 1'b0;
        end
        else begin
            sin_reg <= sin;
        end
    end
    
    // 中间数据寄存器
    reg [DATA_BITS-1:0] data_reg;
    
    // 使用data_reg计算奇偶校验
    wire parity;
    assign parity = ^data_reg;
    
    // 主要移位操作和奇偶校验赋值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 0;
            sreg <= 0;
        end
        else begin
            data_reg <= sreg[DATA_BITS-1:0];
            sreg[DATA_BITS-1:0] <= {data_reg[DATA_BITS-2:0], sin_reg};
            sreg[DATA_BITS] <= parity;
        end
    end
endmodule