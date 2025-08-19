//SystemVerilog
// 加法子模块 - 使用曼彻斯特进位链加法器实现
module adder (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    wire [7:0] p; // 传播信号
    wire [7:0] g; // 生成信号
    wire [7:0] c; // 进位信号
    
    // 第一阶段：计算传播和生成信号
    assign p = a ^ b; // 传播信号
    assign g = a & b; // 生成信号
    
    // 第二阶段：计算进位链
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign c[4] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]);
    assign c[5] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    assign c[6] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    assign c[7] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    
    // 第三阶段：计算和
    assign sum[0] = p[0];
    assign sum[7:1] = p[7:1] ^ c[6:0];
endmodule

// 与操作子模块
module and_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] and_result
);
    assign and_result = a & b;
endmodule

// 顶层模块
module add_and_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output [7:0] and_result
);
    // 实例化加法子模块
    adder adder_inst (
        .a(a),
        .b(b),
        .sum(sum)
    );

    // 实例化与操作子模块
    and_operator and_inst (
        .a(a),
        .b(b),
        .and_result(and_result)
    );
endmodule