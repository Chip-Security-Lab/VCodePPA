//SystemVerilog
module parity_check_async_rst (
    input clk, arst,
    input [3:0] addr,
    input [7:0] data,
    output reg parity
);
    // 数据流中间寄存器
    reg [7:0] data_reg;

    // 第一级：数据寄存
    always @(posedge clk or posedge arst) begin
        if (arst) 
            data_reg <= 8'b0;
        else 
            data_reg <= data;
    end
    
    // 第二级：奇偶校验计算
    always @(posedge clk or posedge arst) begin
        if (arst) 
            parity <= 1'b0;
        else 
            parity <= ~(^data_reg); // 直接在这里计算并输出奇偶校验结果
    end
endmodule