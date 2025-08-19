//SystemVerilog
module crc8_with_enable(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [7:0] data,
    output reg [7:0] crc
);
    parameter POLY = 8'h07;
    
    reg [7:0] bit0_crc, bit1_crc, bit2_crc, bit3_crc;
    reg [7:0] bit4_crc, bit5_crc, bit6_crc, bit7_crc;
    
    // Calculate CRC in stages with if-else instead of conditional operators
    always @(*) begin
        // Bit 0 calculation
        if (crc[7] ^ data[0]) 
            bit0_crc = {crc[6:0], 1'b0} ^ POLY;
        else
            bit0_crc = {crc[6:0], 1'b0};
            
        // Bit 1 calculation
        if (bit0_crc[7] ^ data[1])
            bit1_crc = {bit0_crc[6:0], 1'b0} ^ POLY;
        else
            bit1_crc = {bit0_crc[6:0], 1'b0};
            
        // Bit 2 calculation
        if (bit1_crc[7] ^ data[2])
            bit2_crc = {bit1_crc[6:0], 1'b0} ^ POLY;
        else
            bit2_crc = {bit1_crc[6:0], 1'b0};
            
        // Bit 3 calculation
        if (bit2_crc[7] ^ data[3])
            bit3_crc = {bit2_crc[6:0], 1'b0} ^ POLY;
        else
            bit3_crc = {bit2_crc[6:0], 1'b0};
            
        // Bit 4 calculation
        if (bit3_crc[7] ^ data[4])
            bit4_crc = {bit3_crc[6:0], 1'b0} ^ POLY;
        else
            bit4_crc = {bit3_crc[6:0], 1'b0};
            
        // Bit 5 calculation
        if (bit4_crc[7] ^ data[5])
            bit5_crc = {bit4_crc[6:0], 1'b0} ^ POLY;
        else
            bit5_crc = {bit4_crc[6:0], 1'b0};
            
        // Bit 6 calculation
        if (bit5_crc[7] ^ data[6])
            bit6_crc = {bit5_crc[6:0], 1'b0} ^ POLY;
        else
            bit6_crc = {bit5_crc[6:0], 1'b0};
            
        // Bit 7 calculation
        if (bit6_crc[7] ^ data[7])
            bit7_crc = {bit6_crc[6:0], 1'b0} ^ POLY;
        else
            bit7_crc = {bit6_crc[6:0], 1'b0};
    end
    
    // Sequential logic for CRC update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            crc <= 8'h00;
        else if (enable) 
            crc <= bit7_crc;
    end
endmodule