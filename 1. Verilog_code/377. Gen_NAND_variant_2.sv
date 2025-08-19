//SystemVerilog - IEEE 1364-2005
module Gen_NAND(
    input [15:0] vec_a, vec_b,
    output [15:0] result
);
    // 内部信号定义
    wire [15:0] p;         // 传播信号
    wire [15:0] g;         // 生成信号
    wire [16:0] c;         // 进位信号
    
    // 第一阶段：生成传播和生成信号
    PG_Generator pg_gen_inst(
        .vec_a(vec_a),
        .vec_b(vec_b),
        .p_out(p),
        .g_out(g)
    );
    
    // 第二阶段：曼彻斯特进位链计算
    Manchester_Carry_Chain carry_chain_inst(
        .p_in(p),
        .g_in(g),
        .c_in(1'b0),
        .c_out(c)
    );
    
    // 第三阶段：计算最终结果
    Sum_Calculator sum_calc_inst(
        .p_in(p),
        .c_in(c[15:0]),
        .sum_out(result)
    );
endmodule

//SystemVerilog - IEEE 1364-2005
module PG_Generator(
    input [15:0] vec_a, vec_b,
    output [15:0] p_out, g_out
);
    // 生成传播和生成信号
    assign p_out = vec_a ^ vec_b;   // 传播 = a XOR b
    assign g_out = vec_a & vec_b;   // 生成 = a AND b
endmodule

//SystemVerilog - IEEE 1364-2005
module Manchester_Carry_Chain(
    input [15:0] p_in, g_in,
    input c_in,
    output [16:0] c_out
);
    // 初始进位
    assign c_out[0] = c_in;
    
    // 曼彻斯特进位链算法实现
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : CARRY_CHAIN
            assign c_out[i+1] = g_in[i] | (p_in[i] & c_out[i]);
        end
    endgenerate
endmodule

//SystemVerilog - IEEE 1364-2005
module Sum_Calculator(
    input [15:0] p_in,
    input [15:0] c_in,
    output [15:0] sum_out
);
    // 计算最终结果
    assign sum_out = p_in ^ c_in;   // 结果 = p XOR c
endmodule