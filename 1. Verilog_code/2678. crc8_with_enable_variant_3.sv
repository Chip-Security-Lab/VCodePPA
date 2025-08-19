//SystemVerilog
module crc8_with_enable(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [7:0] data,
    output reg [7:0] crc
);
    parameter POLY = 8'h07;
    
    wire [7:0] next_crc;
    
    // 使用组合逻辑一次性计算所有位的CRC
    function [7:0] calc_bit_crc;
        input [7:0] current;
        input bit_val;
        begin
            calc_bit_crc = {current[6:0], 1'b0} ^ ((current[7] ^ bit_val) ? POLY : 8'h00);
        end
    endfunction
    
    // 流水线计算CRC，减少逻辑深度
    wire [7:0] bit_crc [0:7];
    
    assign bit_crc[0] = calc_bit_crc(crc, data[0]);
    assign bit_crc[1] = calc_bit_crc(bit_crc[0], data[1]);
    assign bit_crc[2] = calc_bit_crc(bit_crc[1], data[2]);
    assign bit_crc[3] = calc_bit_crc(bit_crc[2], data[3]);
    assign bit_crc[4] = calc_bit_crc(bit_crc[3], data[4]);
    assign bit_crc[5] = calc_bit_crc(bit_crc[4], data[5]);
    assign bit_crc[6] = calc_bit_crc(bit_crc[5], data[6]);
    assign bit_crc[7] = calc_bit_crc(bit_crc[6], data[7]);
    
    assign next_crc = bit_crc[7];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            crc <= 8'h00;
        else if (enable) 
            crc <= next_crc;
    end
endmodule