module CascadeNOT(
    input [3:0] bits,
    output [3:0] inv_bits
);
    not(inv_bits[0], bits[0]);
    not(inv_bits[1], bits[1]);
    not(inv_bits[2], bits[2]);
    not(inv_bits[3], bits[3]);  // 离散门级描述
endmodule
