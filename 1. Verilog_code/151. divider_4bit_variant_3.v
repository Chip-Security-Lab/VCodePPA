module divider_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder
);

    wire [3:0] q;
    wire [3:0] r;
    wire [3:0] temp_a = a;
    wire [3:0] temp_b = b;
    
    // 使用组合逻辑实现除法
    wire [3:0] r0 = {3'b0, temp_a[3]};
    wire [3:0] r1 = (r0 >= temp_b) ? (r0 - temp_b) : r0;
    wire [3:0] r2 = {r1[2:0], temp_a[2]};
    wire [3:0] r3 = (r2 >= temp_b) ? (r2 - temp_b) : r2;
    wire [3:0] r4 = {r3[2:0], temp_a[1]};
    wire [3:0] r5 = (r4 >= temp_b) ? (r4 - temp_b) : r4;
    wire [3:0] r6 = {r5[2:0], temp_a[0]};
    wire [3:0] r7 = (r6 >= temp_b) ? (r6 - temp_b) : r6;
    
    // 商的计算
    wire [3:0] q0 = {3'b0, (r0 >= temp_b)};
    wire [3:0] q1 = {q0[2:0], (r2 >= temp_b)};
    wire [3:0] q2 = {q1[2:0], (r4 >= temp_b)};
    wire [3:0] q3 = {q2[2:0], (r6 >= temp_b)};
    
    // 处理除数为0的情况
    assign quotient = (temp_b == 4'b0) ? 4'b1111 : q3;
    assign remainder = (temp_b == 4'b0) ? 4'b1111 : r7;
    
endmodule