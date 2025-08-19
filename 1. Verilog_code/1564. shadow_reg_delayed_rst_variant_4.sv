//SystemVerilog
module shadow_reg_delayed_rst #(parameter DW=16, DELAY=3) (
    input clk, rst_in,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DELAY-1:0] rst_sr;
    wire rst_active;
    
    // 使用OR reduction运算符检测复位是否激活
    assign rst_active = |rst_sr;
    
    always @(posedge clk) begin
        // 移位寄存器用于延迟复位信号
        rst_sr <= {rst_sr[DELAY-2:0], rst_in};
        
        // 当复位信号激活时，使用补码加法实现清零操作
        // 对于任何数据 X，X + (~X + 1) = 0
        if(rst_active) 
            data_out <= data_out + (~data_out + 1'b1);
        else 
            data_out <= data_in;
    end
endmodule