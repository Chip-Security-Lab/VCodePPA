module Primitive_NAND(
    input in1, in2,
    output out
);
    nand U1(out, in1, in2);  // 门级原语
endmodule
