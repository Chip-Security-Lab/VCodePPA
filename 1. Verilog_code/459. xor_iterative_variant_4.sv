//SystemVerilog
module xor_iterative(
    input [4:0] x,         // 扩展为5位
    input [4:0] y,         // 扩展为5位
    output [4:0] z         // 扩展为5位
);
    // 内部连线
    wire [4:0] g;          // Generate信号
    wire [4:0] p;          // Propagate信号
    wire [1:0] GG;         // 组间Generate信号
    wire [1:0] PP;         // 组间Propagate信号
    wire [6:0] c;          // Carry信号，包括初始进位和各级跳跃进位
    wire [4:0] sum;        // 加法和
    
    // 第一级：生成基本的g和p信号
    generate_propagate_unit gp_unit (
        .x(x),
        .y(y),
        .g(g),
        .p(p)
    );
    
    // 第二级：跳跃进位逻辑
    skip_carry_unit skip_unit (
        .g(g),
        .p(p),
        .cin(1'b0),
        .GG(GG),
        .PP(PP),
        .c(c)
    );
    
    // 第三级：计算最终和
    sum_calculation_unit sum_unit (
        .x(x),
        .y(y),
        .c(c[4:0]),
        .sum(sum)
    );
    
    // 输出赋值
    assign z = sum;
    
endmodule

// 产生Generate和Propagate信号的子模块
module generate_propagate_unit(
    input [4:0] x,
    input [4:0] y,
    output [4:0] g,
    output [4:0] p
);
    // 更精确的Generate和Propagate定义
    assign g = x & y;       // Generate: 当x和y都为1时产生进位
    assign p = x ^ y;       // Propagate: 当x和y不同时可能传播进位
endmodule

// 跳跃进位加法器逻辑子模块
module skip_carry_unit(
    input [4:0] g,
    input [4:0] p,
    input cin,
    output [1:0] GG,        // 块Generate
    output [1:0] PP,        // 块Propagate
    output [6:0] c          // 所有进位信号
);
    // 第一级进位计算
    assign c[0] = cin;
    
    // 分组 - 前3位为一组，后2位为一组
    // 计算第一组的块Generate和块Propagate
    assign GG[0] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign PP[0] = p[2] & p[1] & p[0];
    
    // 计算第二组的块Generate和块Propagate
    assign GG[1] = g[4] | (p[4] & g[3]);
    assign PP[1] = p[4] & p[3];
    
    // 计算各位进位
    // 第一组内部进位
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    
    // 第一组到第二组的进位
    assign c[3] = GG[0] | (PP[0] & cin);
    
    // 第二组内部进位
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & c[3]);
    
    // 最终进位输出（如果需要）
    assign c[6] = GG[1] | (PP[1] & c[3]);
endmodule

// 计算和的子模块
module sum_calculation_unit(
    input [4:0] x,
    input [4:0] y,
    input [4:0] c,
    output [4:0] sum
);
    // 使用异或计算每一位的和
    assign sum = x ^ y ^ c;
endmodule