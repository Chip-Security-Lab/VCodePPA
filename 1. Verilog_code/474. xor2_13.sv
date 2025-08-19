module xor2_13 (
    input wire A, B,
    output reg Y
);
    always @(A or B) begin
        Y = A ^ B; // 使用`always`块模拟异或操作
    end
endmodule
