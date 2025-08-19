module multiplier_pipeline (
    input [7:0] a, 
    input [7:0] b,
    output [15:0] product
);
    reg [15:0] p1, p2, p3;
    always @(a, b) begin
        p1 = a * b;    // 第一级计算
        p2 = p1 + 1;   // 第二级延迟
        p3 = p2 + 1;   // 第三级延迟
    end
    assign product = p3;  // 输出最终结果
endmodule
