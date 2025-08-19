module nor4_reset (
    input wire A, B, C, D,
    input wire reset,
    output reg Y
);
    always @(*) begin
        if (reset) begin
            Y = 1'b1;  // 异步复位信号，输出为 1
        end else begin
            Y = ~(A | B | C | D);  // 正常情况下计算 NOR
        end
    end
endmodule
