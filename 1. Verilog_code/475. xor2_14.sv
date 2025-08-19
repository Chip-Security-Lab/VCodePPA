module xor2_14 (
    input wire A, B,
    output reg Y
);
    always @(A or B) begin
        Y <= A ^ B; // 异或门与寄存器输出
    end
endmodule
