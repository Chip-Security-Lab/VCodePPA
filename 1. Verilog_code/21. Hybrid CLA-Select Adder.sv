// 混合8位CLA-选择加法器
module hybrid_adder(
    input [7:0] a, b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [3:0] sum_low, sum_high;
    wire carry_mid;
    
    cla_adder low(a[3:0], b[3:0], cin, sum_low, carry_mid);
    carry_select_adder high(a[7:4], b[7:4], carry_mid, sum_high, cout);
    
    assign sum = {sum_high, sum_low};
endmodule

// 简单的4位行波进位加法器
module ripple_carry_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [4:0] c;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : ripple
            full_adder fa(
                .a(a[i]),
                .b(b[i]),
                .cin(c[i]),
                .sum(sum[i]),
                .cout(c[i+1])
            );
        end
    endgenerate
    
    assign cout = c[4];
endmodule

// 4位选择进位加法器
module carry_select_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] sum0, sum1;
    wire cout0, cout1;
    
    // 两个并行加法器，一个cin=0，一个cin=1
    ripple_carry_adder rca0(a, b, 1'b0, sum0, cout0);
    ripple_carry_adder rca1(a, b, 1'b1, sum1, cout1);
    
    // 根据cin选择正确的sum和cout
    assign sum = cin ? sum1 : sum0;
    assign cout = cin ? cout1 : cout0;
endmodule

// 全加器模块
module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 4位超前进位加法器
module cla_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g; // 传播和生成信号
    wire [4:0] c;    // 进位
    
    // 生成传播和生成信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 计算进位
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 求和输出
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule