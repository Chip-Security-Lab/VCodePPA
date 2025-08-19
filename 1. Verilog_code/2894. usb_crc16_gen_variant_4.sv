//SystemVerilog
module usb_crc16_gen(
    input [7:0] data_in,
    input [15:0] crc_in,
    output [15:0] crc_out
);
    // Grouping common terms for better logic optimization
    wire [7:0] data_reduced;
    wire [7:0] crc_high;
    
    // Reduce input data bits with simplified XOR tree structure
    assign data_reduced = data_in[0] ^ {data_in[7:1]};
    
    // Group high bits of CRC for reuse
    assign crc_high = crc_in[15:8];
    
    // CRC calculation with optimized boolean expressions
    assign crc_out[0] = ^{data_reduced, crc_high};
    assign crc_out[1] = ^{data_reduced, data_in[0], crc_high[7:1]};
    assign crc_out[2] = ^{data_in[1:0], crc_high[7:2]};
    assign crc_out[3] = ^{data_in[2:1], crc_high[7:3]};
    assign crc_out[4] = ^{data_in[3:2], crc_high[7:4]};
    assign crc_out[5] = ^{data_in[4:3], crc_high[7:5]};
    assign crc_out[6] = ^{data_in[5:4], crc_high[7:6]};
    assign crc_out[7] = ^{data_in[6:5], crc_high[7]};
    assign crc_out[8] = ^{data_in[7:6], crc_in[0]};
    assign crc_out[9] = data_in[7] ^ crc_in[1];
    
    // Direct pass-through for middle bits (no XOR operations needed)
    assign crc_out[14:10] = crc_in[6:2];
    
    // Optimized calculation for last bit using reduction operator
    assign crc_out[15] = ^{data_reduced, crc_in[7], crc_high};
endmodule