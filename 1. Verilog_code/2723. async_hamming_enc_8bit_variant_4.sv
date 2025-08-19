//SystemVerilog
module async_hamming_enc_8bit(
    input [7:0] din,
    output [11:0] enc_out
);
    // Optimized parity bit calculations
    wire p0, p1, p3, p11;
    wire [3:0] parity_group;
    
    // Combined XOR operations with better grouping
    assign parity_group[0] = din[0] ^ din[4];
    assign parity_group[1] = din[1] ^ din[3];
    assign parity_group[2] = din[2] ^ din[6];
    assign parity_group[3] = din[5] ^ din[7];
    
    // Optimized parity bit generation reduces logic depth
    assign p0 = parity_group[0] ^ parity_group[1] ^ din[6];
    assign p1 = parity_group[0] ^ parity_group[2] ^ din[5];
    assign p3 = parity_group[1] ^ din[2] ^ din[7];
    
    // Overall parity bit using reduced XOR tree structure
    assign p11 = ^{din, p0, p1, p3};
    
    // Direct output assignment
    assign enc_out = {p11, din[7:0], p3, din[0], p1, p0};
endmodule