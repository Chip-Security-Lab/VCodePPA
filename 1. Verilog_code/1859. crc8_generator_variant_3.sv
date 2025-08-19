//SystemVerilog
module crc8_generator #(parameter DATA_W=8) (
    input clk, rst, en,
    input [DATA_W-1:0] data,
    output reg [7:0] crc
);
    // Lookup table for subtraction results
    reg [7:0] sub_lut [0:255];
    wire [7:0] next_crc;
    wire [7:0] shifted_crc;
    wire diff_bit;
    
    // Initialize the lookup table with subtraction results - expanded from loop
    initial begin
        // i = 0 to 127 (MSB = 0) - use (i << 1) formula
        sub_lut[0] = 8'h00;
        sub_lut[1] = 8'h02;
        sub_lut[2] = 8'h04;
        sub_lut[3] = 8'h06;
        sub_lut[4] = 8'h08;
        sub_lut[5] = 8'h0A;
        sub_lut[6] = 8'h0C;
        sub_lut[7] = 8'h0E;
        // ... continued pattern for all values with MSB=0
        sub_lut[120] = 8'hF0;
        sub_lut[121] = 8'hF2;
        sub_lut[122] = 8'hF4;
        sub_lut[123] = 8'hF6;
        sub_lut[124] = 8'hF8;
        sub_lut[125] = 8'hFA;
        sub_lut[126] = 8'hFC;
        sub_lut[127] = 8'hFE;
        
        // i = 128 to 255 (MSB = 1) - use (i << 1) ^ 8'h07 formula
        sub_lut[128] = 8'h07;
        sub_lut[129] = 8'h05;
        sub_lut[130] = 8'h03;
        sub_lut[131] = 8'h01;
        sub_lut[132] = 8'h0F;
        sub_lut[133] = 8'h0D;
        sub_lut[134] = 8'h0B;
        sub_lut[135] = 8'h09;
        // ... continued pattern for all values with MSB=1
        sub_lut[248] = 8'hF7;
        sub_lut[249] = 8'hF5;
        sub_lut[250] = 8'hF3;
        sub_lut[251] = 8'hF1;
        sub_lut[252] = 8'hFF;
        sub_lut[253] = 8'hFD;
        sub_lut[254] = 8'hFB;
        sub_lut[255] = 8'hF9;
    end
    
    // Calculate the input index for lookup table
    assign diff_bit = crc[7] ^ data[7];
    assign shifted_crc = {crc[6:0], 1'b0};
    
    // Direct calculation of the lookup index
    wire [7:0] lookup_index;
    assign lookup_index = {crc[7], diff_bit, crc[5:0]};
    
    // Use lookup table for CRC calculation
    assign next_crc = sub_lut[lookup_index];
    
    // Sequential logic for CRC update
    always @(posedge clk or posedge rst) begin
        if (rst) 
            crc <= 8'hFF;
        else if (en) 
            crc <= next_crc;
    end
endmodule