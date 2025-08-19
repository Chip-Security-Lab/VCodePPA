//SystemVerilog
module subpixel_render (
    input [7:0] px1, px2,
    output [7:0] px_out
);
    wire [15:0] px1_mul_3;
    wire [7:0] px2_mul_1;
    wire [15:0] sum_result;
    
    karatsuba_multiplier_8bit km1 (
        .a(px1),
        .b(8'd3),
        .y(px1_mul_3)
    );
    
    assign px2_mul_1 = px2; // Multiplication by 1 is identity
    
    // 使用先行进位加法器 (16位)
    carry_lookahead_adder_16bit cla (
        .a(px1_mul_3),
        .b({8'b0, px2_mul_1}),
        .cin(1'b0),
        .sum(sum_result),
        .cout()
    );
    
    assign px_out = sum_result[9:2]; // Equivalent to >> 2
endmodule

module karatsuba_multiplier_8bit (
    input [7:0] a,
    input [7:0] b,
    output [15:0] y
);
    // Split inputs into high and low halves
    wire [3:0] a_high, a_low, b_high, b_low;
    
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // Compute three products for Karatsuba algorithm
    wire [7:0] p1, p2, p3;
    wire [7:0] sum_a, sum_b;
    
    assign sum_a = {4'b0, a_low} + {4'b0, a_high};
    assign sum_b = {4'b0, b_low} + {4'b0, b_high};
    
    // Compute the three products
    // p1 = a_high * b_high
    // p2 = a_low * b_low
    // p3 = (a_high + a_low) * (b_high + b_low) - p1 - p2
    
    mul4x4 m1 (
        .a(a_high),
        .b(b_high),
        .y(p1)
    );
    
    mul4x4 m2 (
        .a(a_low),
        .b(b_low),
        .y(p2)
    );
    
    mul4x4 m3 (
        .a(sum_a[3:0]),
        .b(sum_b[3:0]),
        .y(p3)
    );
    
    // Karatsuba formula: result = p1*2^8 + (p3 - p1 - p2)*2^4 + p2
    wire [7:0] middle_term;
    assign middle_term = p3 - p1 - p2;
    
    // Combine the partial products
    assign y = {p1, 8'b0} + {4'b0, middle_term, 4'b0} + {8'b0, p2};
endmodule

module mul4x4 (
    input [3:0] a,
    input [3:0] b,
    output [7:0] y
);
    // Simple 4x4 multiplier
    assign y = a * b;
endmodule

module carry_lookahead_adder_16bit (
    input [15:0] a, b,
    input cin,
    output [15:0] sum,
    output cout
);
    wire [3:0] carry;
    
    // 使用4个4位先行进位加法器级联
    carry_lookahead_adder_4bit cla0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .sum(sum[3:0]),
        .cout(carry[0])
    );
    
    carry_lookahead_adder_4bit cla1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(carry[0]),
        .sum(sum[7:4]),
        .cout(carry[1])
    );
    
    carry_lookahead_adder_4bit cla2 (
        .a(a[11:8]),
        .b(b[11:8]),
        .cin(carry[1]),
        .sum(sum[11:8]),
        .cout(carry[2])
    );
    
    carry_lookahead_adder_4bit cla3 (
        .a(a[15:12]),
        .b(b[15:12]),
        .cin(carry[2]),
        .sum(sum[15:12]),
        .cout(carry[3])
    );
    
    assign cout = carry[3];
endmodule

module carry_lookahead_adder_4bit (
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g;
    wire [4:0] c;
    
    // 生成传播和生成信号
    assign p = a ^ b;  // 传播(Propagate)
    assign g = a & b;  // 生成(Generate)
    
    // 计算先行进位
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 计算和
    assign sum = p ^ {c[3:0]};
    assign cout = c[4];
endmodule