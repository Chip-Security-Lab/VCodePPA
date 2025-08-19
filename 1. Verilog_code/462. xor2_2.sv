module xor2_2 (
    input wire A, B,
    output reg Y
);
    always @(A or B) begin
        if (A == B)
            Y = 0; // 相等时输出0
        else
            Y = 1; // 不相等时输出1
    end
endmodule
