module XNOR_Basic(
    input a, b,
    output y
);
    assign y = ~(a ^ b); // 标准两输入同或门
endmodule

