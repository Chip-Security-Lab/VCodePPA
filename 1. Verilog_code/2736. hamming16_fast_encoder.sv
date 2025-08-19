module hamming16_fast_encoder(
    input [15:0] raw_data,
    output [21:0] encoded_data
);
    wire [4:0] parity;
    
    // Parallel parity calculation for better timing
    assign parity[0] = ^(raw_data & 16'b1010_1010_1010_1010);
    assign parity[1] = ^(raw_data & 16'b1100_1100_1100_1100);
    assign parity[2] = ^(raw_data & 16'b1111_0000_1111_0000);
    assign parity[3] = ^(raw_data & 16'b1111_1111_0000_0000);
    assign parity[4] = ^{parity[3:0], raw_data}; // Overall parity
    
    // Assemble encoded data (simplified for brevity)
    assign encoded_data = {raw_data[15:11], parity[3], 
                          raw_data[10:4], parity[2],
                          raw_data[3:1], parity[1],
                          raw_data[0], parity[0], parity[4]};
endmodule