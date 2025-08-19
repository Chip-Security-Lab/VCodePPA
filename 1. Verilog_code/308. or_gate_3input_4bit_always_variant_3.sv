//SystemVerilog
// SystemVerilog - 顶层模块
module or_gate_3input_4bit_always (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output wire [3:0] y
);
    // 内部连接信号
    wire [3:0] ab_result;
    
    // 实例化第一级Han-Carlson加法器
    han_carlson_adder_4bit adder_ab_inst (
        .a(a),
        .b(b),
        .sum(ab_result),
        .cout()  // 不使用进位输出
    );
    
    // 实例化第二级Han-Carlson加法器
    han_carlson_adder_4bit adder_abc_inst (
        .a(ab_result),
        .b(c),
        .sum(y),
        .cout()  // 不使用进位输出
    );
endmodule

// 4位Han-Carlson加法器模块
module han_carlson_adder_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] sum,
    output wire cout
);
    // 预处理阶段 - 生成p和g信号
    wire [3:0] p, g;
    
    // 中间信号
    wire [3:0] p_mid, g_mid;
    wire [3:0] p_final, g_final;
    
    // 预处理：计算每位的传播p和生成g信号
    assign p = a ^ b;  // 传播信号
    assign g = a & b;  // 生成信号
    
    // Han-Carlson偶数位处理
    assign p_mid[0] = p[0];
    assign g_mid[0] = g[0];
    
    assign p_mid[2] = p[2];
    assign g_mid[2] = g[2];
    
    // Han-Carlson奇数位处理
    assign p_mid[1] = p[1] & p[0];
    assign g_mid[1] = g[1] | (p[1] & g[0]);
    
    assign p_mid[3] = p[3] & p[2];
    assign g_mid[3] = g[3] | (p[3] & g[2]);
    
    // Han-Carlson第二阶段传播
    assign p_final[0] = p_mid[0];
    assign g_final[0] = g_mid[0];
    
    assign p_final[1] = p_mid[1];
    assign g_final[1] = g_mid[1];
    
    assign p_final[2] = p_mid[2] & p_mid[0];
    assign g_final[2] = g_mid[2] | (p_mid[2] & g_mid[0]);
    
    assign p_final[3] = p_mid[3] & p_mid[1];
    assign g_final[3] = g_mid[3] | (p_mid[3] & g_mid[1]);
    
    // 后处理：计算最终的和与进位
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ g_final[0];
    assign sum[2] = p[2] ^ g_final[1];
    assign sum[3] = p[3] ^ g_final[2];
    
    // 最高位进位输出
    assign cout = g_final[3];
endmodule