module xor_multi_driver(
    input a, b,
    output y
);
    wire y1 = a ^ b;
    wire y2 = a ^ b;
    assign y = y1 & y2; // 冗余设计确保正确性
endmodule