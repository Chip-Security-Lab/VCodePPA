module nor2_delay (
    input wire A, B,
    output wire Y
);
    assign #5 Y = ~(A | B);  // 增加延时
endmodule
