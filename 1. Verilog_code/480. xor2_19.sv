module xor2_19 (
    input wire A, B,
    output wire Y
);
    reg result;
    always @(A or B) begin
        result = A ^ B; // 使用寄存器存储中间结果
    end
    assign Y = result; // 将寄存器值传递给输出
endmodule
