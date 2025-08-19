module hamming_8bit_secded(
    input [7:0] data,
    output [12:0] code
);
    wire [3:0] parity;
    wire overall_parity;
    
    // Calculate parity bits
    assign parity[0] = ^(data & 8'b10101010);
    assign parity[1] = ^(data & 8'b11001100);
    assign parity[2] = ^(data & 8'b11110000);
    assign parity[3] = ^data;
    
    // Calculate overall parity for double error detection
    assign overall_parity = ^{parity, data};
    
    // Assemble code with explicit bit placements
    assign code = {overall_parity,
                  data[7:4],
                  parity[3],
                  data[3:1],
                  parity[2],
                  data[0],
                  parity[1],
                  parity[0]};
endmodule