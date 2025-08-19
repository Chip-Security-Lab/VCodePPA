module nor3_enable (
    input wire A, B, C,
    input wire enable,
    output wire Y
);
    assign Y = enable ? ~(A | B | C) : 1'b1;  // 如果使能信号为 0，输出为 1
endmodule
