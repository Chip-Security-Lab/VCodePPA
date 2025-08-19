//SystemVerilog
module carry_save_mult (
    input [3:0] A, B,
    output [7:0] Prod
);
    // 部分积生成
    wire [3:0] pp0 = A & {4{B[0]}};
    wire [3:0] pp1 = A & {4{B[1]}};
    wire [3:0] pp2 = A & {4{B[2]}};
    wire [3:0] pp3 = A & {4{B[3]}};

    // 优化后的进位保存加法器结构
    wire [4:0] sum1, carry1;
    wire [5:0] sum2, carry2;
    wire [6:0] sum3, carry3;
    
    // 第一级加法 - 使用位拼接优化
    assign {carry1, sum1} = {1'b0, pp0} + {1'b0, pp1};
    
    // 第二级加法 - 使用位拼接优化
    assign {carry2, sum2} = {carry1, sum1} + {2'b0, pp2};
    
    // 第三级加法 - 使用位拼接优化
    assign {carry3, sum3} = {carry2, sum2} + {3'b0, pp3};
    
    // 最终结果 - 使用位拼接优化
    assign Prod = {carry3, sum3};
endmodule