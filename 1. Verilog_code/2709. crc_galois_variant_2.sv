//SystemVerilog
module crc_galois (
    input clk, rst_n,
    input [7:0] data,
    output reg [7:0] crc
);
    parameter POLY = 8'hD5;
    
    wire [7:0] xord;
    wire [7:0] final_crc;
    
    assign xord = crc ^ data;
    
    crc_calc #(.POLY(POLY)) calc_inst (
        .xord(xord),
        .crc_out(final_crc)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) crc <= 8'h00;
        else crc <= final_crc;
    end
endmodule

module crc_calc #(
    parameter POLY = 8'hD5
)(
    input [7:0] xord,
    output [7:0] crc_out
);
    wire [7:0] bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7;
    
    assign bit0 = {xord[6:0], 1'b0} ^ (xord[7] ? POLY : 0);
    assign bit1 = {bit0[6:0], 1'b0} ^ (bit0[7] ? POLY : 0);
    assign bit2 = {bit1[6:0], 1'b0} ^ (bit1[7] ? POLY : 0);
    assign bit3 = {bit2[6:0], 1'b0} ^ (bit2[7] ? POLY : 0);
    assign bit4 = {bit3[6:0], 1'b0} ^ (bit3[7] ? POLY : 0);
    assign bit5 = {bit4[6:0], 1'b0} ^ (bit4[7] ? POLY : 0);
    assign bit6 = {bit5[6:0], 1'b0} ^ (bit5[7] ? POLY : 0);
    assign bit7 = {bit6[6:0], 1'b0} ^ (bit6[7] ? POLY : 0);
    
    assign crc_out = bit7;
endmodule