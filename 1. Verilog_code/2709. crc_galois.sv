module crc_galois (
    input clk, rst_n,
    input [7:0] data,
    output reg [7:0] crc
);
    parameter POLY = 8'hD5;
    
    // 展开位操作
    wire [7:0] xord = crc ^ data;
    
    wire [7:0] bit0 = {xord[6:0], 1'b0} ^ (xord[7] ? POLY : 0);
    wire [7:0] bit1 = {bit0[6:0], 1'b0} ^ (bit0[7] ? POLY : 0);
    wire [7:0] bit2 = {bit1[6:0], 1'b0} ^ (bit1[7] ? POLY : 0);
    wire [7:0] bit3 = {bit2[6:0], 1'b0} ^ (bit2[7] ? POLY : 0);
    wire [7:0] bit4 = {bit3[6:0], 1'b0} ^ (bit3[7] ? POLY : 0);
    wire [7:0] bit5 = {bit4[6:0], 1'b0} ^ (bit4[7] ? POLY : 0);
    wire [7:0] bit6 = {bit5[6:0], 1'b0} ^ (bit5[7] ? POLY : 0);
    wire [7:0] bit7 = {bit6[6:0], 1'b0} ^ (bit6[7] ? POLY : 0);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) crc <= 8'h00;
        else crc <= bit7;
    end
endmodule