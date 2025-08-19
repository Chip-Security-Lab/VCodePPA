//SystemVerilog
`timescale 1ns / 1ps
module multichannel_buffer (
    input wire clk,
    input wire [3:0] channel_select,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] data_out
);
    reg [7:0] channels [0:15];
    reg [3:0] channel_select_reg;
    reg [7:0] data_in_reg;
    reg write_en_reg;
    
    // 将输入信号寄存器化，减少输入端到第一级寄存器之间的延迟
    always @(posedge clk) begin
        channel_select_reg <= channel_select;
        data_in_reg <= data_in;
        write_en_reg <= write_en;
    end
    
    // 使用寄存器化的输入信号进行内存操作
    always @(posedge clk) begin
        if (write_en_reg)
            channels[channel_select_reg] <= data_in_reg;
        data_out <= channels[channel_select_reg];
    end
endmodule