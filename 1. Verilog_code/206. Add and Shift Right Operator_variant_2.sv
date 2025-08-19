//SystemVerilog
module add_shift_right (
    input [7:0] a,
    input [7:0] b,
    input [2:0] shift_amount,
    output [7:0] sum,
    output [7:0] shifted_result
);
    // 内部连线
    wire [7:0] p, g;
    wire [8:0] c;
    
    // 初始生成和传播信号计算
    pg_generator pg_gen_inst (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );
    
    // Brent-Kung加法器进位生成网络
    brent_kung_carry_generator bk_carry_gen (
        .p(p),
        .g(g),
        .c(c)
    );
    
    // 最终求和模块
    sum_calculator sum_calc (
        .p(p),
        .c(c[7:0]),
        .sum(sum)
    );
    
    // 右移操作模块
    barrel_shifter shifter (
        .data_in(a),
        .shift_amount(shift_amount),
        .data_out(shifted_result)
    );
endmodule

//------------------------------------------------------
// 生成与传播信号计算模块
//------------------------------------------------------
module pg_generator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] p,
    output [7:0] g
);
    // 生成传播和生成信号
    assign p = a ^ b; // 传播信号
    assign g = a & b; // 生成信号
endmodule

//------------------------------------------------------
// Brent-Kung进位生成网络
//------------------------------------------------------
module brent_kung_carry_generator (
    input [7:0] p,
    input [7:0] g,
    output [8:0] c
);
    // 中间信号声明
    wire [7:0] pp, gg;     // 第一级传播和生成
    wire [7:0] ppp, ggg;   // 第二级传播和生成
    
    // 初始进位为0
    assign c[0] = 1'b0;
    
    // 第1级：2位组合
    assign pp[1] = p[1] & p[0];
    assign gg[1] = g[1] | (p[1] & g[0]);
    assign pp[3] = p[3] & p[2];
    assign gg[3] = g[3] | (p[3] & g[2]);
    assign pp[5] = p[5] & p[4];
    assign gg[5] = g[5] | (p[5] & g[4]);
    assign pp[7] = p[7] & p[6];
    assign gg[7] = g[7] | (p[7] & g[6]);

    // 第2级：4位组合
    assign ppp[3] = pp[3] & pp[1];
    assign ggg[3] = gg[3] | (pp[3] & gg[1]);
    assign ppp[7] = pp[7] & pp[5];
    assign ggg[7] = gg[7] | (pp[7] & gg[5]);

    // 进位生成
    assign c[1] = g[0];
    assign c[2] = gg[1];
    assign c[3] = g[2] | (p[2] & gg[1]);
    assign c[4] = ggg[3];
    assign c[5] = g[4] | (p[4] & ggg[3]);
    assign c[6] = gg[5] | (pp[5] & ggg[3]);
    assign c[7] = g[6] | (p[6] & (gg[5] | (pp[5] & ggg[3])));
    assign c[8] = gg[7] | (pp[7] & ggg[3]);
endmodule

//------------------------------------------------------
// 和计算模块
//------------------------------------------------------
module sum_calculator (
    input [7:0] p,
    input [7:0] c,
    output [7:0] sum
);
    // 使用传播信号和进位计算和
    assign sum = p ^ c;
endmodule

//------------------------------------------------------
// 桶形移位器模块
//------------------------------------------------------
module barrel_shifter (
    input [7:0] data_in,
    input [2:0] shift_amount,
    output [7:0] data_out
);
    // 实现可参数化的右移操作
    assign data_out = data_in >> shift_amount;
endmodule