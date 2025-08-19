//SystemVerilog
module hamming16_fast_encoder(
    input [15:0] raw_data,
    output [21:0] encoded_data
);
    wire [4:0] parity;
    
    // Optimized parity calculation using selective XOR
    // Using bit slicing and concatenation to reduce logic depth
    assign parity[0] = ^{raw_data[14], raw_data[12], raw_data[10], raw_data[8], 
                         raw_data[6], raw_data[4], raw_data[2], raw_data[0]};
    assign parity[1] = ^{raw_data[13:12], raw_data[9:8], raw_data[5:4], raw_data[1:0]};
    assign parity[2] = ^{raw_data[15:8], raw_data[7:0] & 8'b11110000};
    assign parity[3] = ^raw_data[15:8];
    
    // Calculate overall parity with reduced fan-in
    wire p_temp1, p_temp2;
    assign p_temp1 = parity[0] ^ parity[1];
    assign p_temp2 = parity[2] ^ parity[3];
    assign parity[4] = p_temp1 ^ p_temp2 ^ ^raw_data;
    
    // Assemble encoded data with bits in correct positions
    assign encoded_data = {raw_data[15:11], parity[3], 
                          raw_data[10:4], parity[2],
                          raw_data[3:1], parity[1],
                          raw_data[0], parity[0], parity[4]};
endmodule