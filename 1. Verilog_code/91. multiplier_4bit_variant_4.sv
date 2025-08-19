//SystemVerilog
module multiplier_4bit (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);

    // 内部信号定义
    wire [7:0] pp0, pp1, pp2, pp3;
    wire [7:0] sum1, sum2;
    
    // 优化的部分积生成和移位
    assign pp0 = {{4{1'b0}}, a & {4{b[0]}}};
    assign pp1 = {{3{1'b0}}, a & {4{b[1]}}, 1'b0};
    assign pp2 = {{2{1'b0}}, a & {4{b[2]}}, {2{1'b0}}};
    assign pp3 = {1'b0, a & {4{b[3]}}, {3{1'b0}}};
    
    // 优化的加法树
    assign sum1 = pp0 + pp1;
    assign sum2 = pp2 + pp3;
    
    // 最终加法
    assign product = sum1 + sum2;

endmodule