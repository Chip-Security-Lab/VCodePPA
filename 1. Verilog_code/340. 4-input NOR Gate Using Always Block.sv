module nor4_always (
    input wire A, B, C, D,
    output reg Y
);
    always @(*) begin
        Y = ~(A | B | C | D);  // 在 always 块内处理
    end
endmodule
