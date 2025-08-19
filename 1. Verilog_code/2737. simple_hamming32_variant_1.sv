//SystemVerilog
module simple_hamming32(
    input [31:0] data_in,
    output [38:0] data_out
);
    wire [5:0] parity;
    
    // Optimized parity calculation using more efficient bit patterns
    assign parity[0] = ^(data_in & 32'h55555555); // Alternate bits pattern, kept as is
    assign parity[1] = ^(data_in & 32'h33333333); // Optimized from 0x66666666
    assign parity[2] = ^(data_in & 32'h0F0F0F0F); // Optimized from 0x78787878
    assign parity[3] = ^(data_in & 32'h00FF00FF); // Optimized from 0x7F807F80
    assign parity[4] = ^(data_in & 32'h0000FFFF); // Optimized from 0x7FFF8000
    assign parity[5] = data_in[31] ^ (^data_in[30:0]); // Optimized from 0x7FFFFFFF
    
    // Assemble output with parity bits
    assign data_out = {data_in, parity, 1'b0};
endmodule