//SystemVerilog
// 顶层模块
module incrementers (
    input [5:0] base,
    output [5:0] double,
    output [5:0] triple
);
    // 实例化双倍子模块
    doubler doubler_inst (
        .base_in(base),
        .double_out(double)
    );
    
    // 实例化三倍子模块
    tripler tripler_inst (
        .base_in(base),
        .triple_out(triple)
    );
endmodule

// 双倍值计算子模块
module doubler (
    input [5:0] base_in,
    output [5:0] double_out
);
    // 参数化移位量，提高可配置性
    parameter SHIFT_AMOUNT = 1;
    
    // 使用移位运算实现乘以2
    assign double_out = base_in << SHIFT_AMOUNT;
endmodule

// 三倍值计算子模块
module tripler (
    input [5:0] base_in,
    output [5:0] triple_out
);
    // 内部信号声明
    wire [5:0] base_doubled;
    
    // 计算中间结果：base_in * 2
    assign base_doubled = base_in << 1;
    
    // 使用Brent-Kung加法器实现加法
    brent_kung_adder adder_inst (
        .a(base_in),
        .b(base_doubled),
        .sum(triple_out)
    );
endmodule

// Brent-Kung加法器实现
module brent_kung_adder (
    input [5:0] a,
    input [5:0] b,
    output [5:0] sum
);
    // 内部信号声明
    wire [5:0] g, p;  // 生成和传播信号
    wire [5:0] c;     // 进位信号
    
    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < 6; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // 计算进位信号
    // 第一级
    wire [2:0] g_level1, p_level1;
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    
    assign g_level1[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign p_level1[2] = p[2] & p[1] & p[0];
    
    // 第二级
    wire [1:0] g_level2, p_level2;
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    
    assign g_level2[1] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[1] = p_level1[2] & p_level1[0];
    
    // 第三级
    wire g_level3, p_level3;
    assign g_level3 = g_level2[0];
    assign p_level3 = p_level2[0];
    
    // 计算最终进位
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g[1] | (p[1] & g[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]);
    
    // 计算最终和
    genvar j;
    generate
        for (j = 0; j < 6; j = j + 1) begin : gen_sum
            assign sum[j] = p[j] ^ c[j];
        end
    endgenerate
endmodule