//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005 Verilog标准
module binary_clk_divider(
    input wire clk_i,
    input wire rst_i,
    input wire ready_i,         // 新增: 接收端准备好接收数据的信号
    output wire valid_o,        // 新增: 输出数据有效信号
    output wire [3:0] clk_div   // 2^1, 2^2, 2^3, 2^4 division
);
    reg [3:0] counter;
    reg [3:0] clk_div_reg;
    reg valid_reg;
    
    // 计数器逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            counter <= 4'b0000;
        else
            counter <= counter + 4'b0001;
    end
    
    // Valid-Ready握手逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_div_reg <= 4'b0000;
            valid_reg <= 1'b0;
        end
        else begin
            // 设置valid信号为高，表示有新数据
            valid_reg <= 1'b1;
            
            // 只有当ready_i为高时，才更新输出寄存器
            if (ready_i && valid_reg) begin
                clk_div_reg <= counter;
            end
        end
    end
    
    // 输出赋值
    assign clk_div = clk_div_reg;
    assign valid_o = valid_reg;
    
endmodule