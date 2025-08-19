module crc8_with_enable(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [7:0] data,
    output reg [7:0] crc
);
    parameter POLY = 8'h07;
    
    wire [7:0] bit0_crc = {crc[6:0], 1'b0} ^ ((crc[7] ^ data[0]) ? POLY : 8'h00);
    wire [7:0] bit1_crc = {bit0_crc[6:0], 1'b0} ^ ((bit0_crc[7] ^ data[1]) ? POLY : 8'h00);
    wire [7:0] bit2_crc = {bit1_crc[6:0], 1'b0} ^ ((bit1_crc[7] ^ data[2]) ? POLY : 8'h00);
    wire [7:0] bit3_crc = {bit2_crc[6:0], 1'b0} ^ ((bit2_crc[7] ^ data[3]) ? POLY : 8'h00);
    wire [7:0] bit4_crc = {bit3_crc[6:0], 1'b0} ^ ((bit3_crc[7] ^ data[4]) ? POLY : 8'h00);
    wire [7:0] bit5_crc = {bit4_crc[6:0], 1'b0} ^ ((bit4_crc[7] ^ data[5]) ? POLY : 8'h00);
    wire [7:0] bit6_crc = {bit5_crc[6:0], 1'b0} ^ ((bit5_crc[7] ^ data[6]) ? POLY : 8'h00);
    wire [7:0] bit7_crc = {bit6_crc[6:0], 1'b0} ^ ((bit6_crc[7] ^ data[7]) ? POLY : 8'h00);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) crc <= 8'h00;
        else if (enable) crc <= bit7_crc;
    end
endmodule