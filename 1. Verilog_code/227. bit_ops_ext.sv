module bit_ops_ext (
    input [3:0] src1,
    input [3:0] src2,
    output [3:0] concat,
    output [3:0] reverse
);
    assign concat = {src1[1:0], src2[1:0]};
    assign reverse = {src1[0], src1[1], src1[2], src1[3]};
endmodule
