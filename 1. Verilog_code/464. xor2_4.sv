module xor2_4 (
    input wire A, B,
    output reg Y
);
    always @(A or B) begin
        Y <= A ^ B; // 使用非阻塞赋值
    end
endmodule
