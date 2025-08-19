module nor3_register (
    input wire A, B, C,
    output wire Y
);
    reg temp1, temp2;
    always @(*) begin
        temp1 = A | B;  // 中间寄存器存储部分计算结果
        temp2 = temp1 | C;
    end
    assign Y = ~temp2;  // 输出反转结果
endmodule
