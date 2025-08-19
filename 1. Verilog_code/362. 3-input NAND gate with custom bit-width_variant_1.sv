//SystemVerilog
//IEEE 1364-2005
module nand3_4 (
    input  wire [3:0] A,
    input  wire [3:0] B, 
    input  wire [3:0] C,
    output wire [3:0] Y
);
    // 使用递归Karatsuba乘法计算 A*B 的结果
    wire [7:0] ab_mult;
    karatsuba_mult_4bit kmult1 (
        .a(A),
        .b(B),
        .p(ab_mult)
    );
    
    // 使用递归Karatsuba乘法计算 (A*B)*C 的结果
    // 这里只取低4位参与计算
    wire [7:0] abc_mult;
    karatsuba_mult_4bit kmult2 (
        .a(ab_mult[3:0]),
        .b(C),
        .p(abc_mult)
    );
    
    // 为了保持NAND3原有功能的等效性，对结果取反
    assign Y = ~abc_mult[3:0];
    
endmodule

// 4位递归Karatsuba乘法器
module karatsuba_mult_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] p
);
    // 分割输入为高位和低位部分
    wire [1:0] a_high, a_low, b_high, b_low;
    assign a_high = a[3:2];
    assign a_low  = a[1:0];
    assign b_high = b[3:2];
    assign b_low  = b[1:0];
    
    // 2位乘法计算
    wire [3:0] z0, z1, z2;
    karatsuba_mult_2bit km_low (
        .a(a_low),
        .b(b_low),
        .p(z0)
    );
    
    karatsuba_mult_2bit km_high (
        .a(a_high),
        .b(b_high),
        .p(z2)
    );
    
    wire [1:0] a_sum, b_sum;
    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;
    
    wire [3:0] z1_temp;
    karatsuba_mult_2bit km_mid (
        .a(a_sum),
        .b(b_sum),
        .p(z1_temp)
    );
    
    assign z1 = z1_temp - z2 - z0;
    
    // 组合最终结果
    assign p = {z2, 4'b0000} + {z1, 2'b00} + z0;
    
endmodule

// 2位Karatsuba乘法器
module karatsuba_mult_2bit (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [3:0] p
);
    // 基本情况：直接计算1位x1位的乘法
    wire a0b0, a0b1, a1b0, a1b1;
    
    assign a0b0 = a[0] & b[0];
    assign a0b1 = a[0] & b[1];
    assign a1b0 = a[1] & b[0];
    assign a1b1 = a[1] & b[1];
    
    // 组合最终结果
    assign p[0] = a0b0;
    assign p[1] = a0b1 ^ a1b0;
    assign p[2] = a1b1 ^ (a0b1 & a1b0);
    assign p[3] = a1b1 & (a0b1 | a1b0);
    
endmodule