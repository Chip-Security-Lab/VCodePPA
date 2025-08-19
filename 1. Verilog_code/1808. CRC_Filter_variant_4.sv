//SystemVerilog
module CRC_Filter #(parameter POLY=16'h8005) (
    input clk,
    input [7:0] data_in,
    output reg [15:0] crc_out
);
    reg [7:0] data_in_reg;
    wire [15:0] crc_next;
    wire [15:0] crc_shifted;
    wire [15:0] crc_poly;
    
    // 前向寄存器重定时 - 将输入数据寄存
    always @(posedge clk) begin
        data_in_reg <= data_in;
    end
    
    // 组合逻辑计算
    assign crc_shifted = {crc_out[7:0], 8'h00};
    assign crc_next = crc_shifted ^ ((data_in_reg ^ crc_out[15:8]) << 8);
    assign crc_poly = POLY & {16{crc_next[15]}};
    
    // 输出寄存器
    always @(posedge clk) begin
        crc_out <= crc_next ^ crc_poly;
    end
endmodule