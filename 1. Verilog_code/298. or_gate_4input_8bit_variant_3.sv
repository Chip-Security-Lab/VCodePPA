//SystemVerilog
// 顶层模块
module or_gate_4input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    output wire [7:0] y
);
    // 内部信号
    wire [7:0] or_result_ab;
    wire [7:0] or_result_cd;
    
    // 实例化第一级OR操作子模块
    kogge_stone_adder_8bit or_ab_inst (
        .a(a),
        .b(b),
        .y(or_result_ab)
    );
    
    kogge_stone_adder_8bit or_cd_inst (
        .a(c),
        .b(d),
        .y(or_result_cd)
    );
    
    // 实例化第二级OR操作子模块
    kogge_stone_adder_8bit or_final_inst (
        .a(or_result_ab),
        .b(or_result_cd),
        .y(y)
    );
endmodule

// Kogge-Stone加法器模块（替代原来的并行前缀加法器）
module kogge_stone_adder_8bit #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    // 生成(G)和传播(P)信号
    wire [WIDTH-1:0] g0, p0;
    
    // 中间生成和传播信号
    wire [WIDTH-1:0] g1, p1;
    wire [WIDTH-1:0] g2, p2;
    wire [WIDTH-1:0] g3, p3;
    
    // 最终进位信号
    wire [WIDTH:0] c;
    
    // 初始化生成和传播信号 (第0级)
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_init_signals
            assign g0[i] = a[i] & b[i];      // 生成信号
            assign p0[i] = a[i] | b[i];      // 传播信号（用OR代替XOR以实现OR功能）
        end
    endgenerate
    
    // 初始进位为0
    assign c[0] = 1'b0;
    
    // Kogge-Stone 网络 - 第1级
    generate
        // 第0位特殊处理
        assign g1[0] = g0[0];
        assign p1[0] = p0[0];
        
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_level1
            assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
            assign p1[i] = p0[i] & p0[i-1];
        end
    endgenerate
    
    // Kogge-Stone 网络 - 第2级
    generate
        // 第0位和第1位特殊处理
        assign g2[0] = g1[0];
        assign p2[0] = p1[0];
        assign g2[1] = g1[1];
        assign p2[1] = p1[1];
        
        for (i = 2; i < WIDTH; i = i + 1) begin : gen_level2
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate
    
    // Kogge-Stone 网络 - 第3级
    generate
        // 第0~3位特殊处理
        for (i = 0; i < 4; i = i + 1) begin : gen_level3_low
            assign g3[i] = g2[i];
            assign p3[i] = p2[i];
        end
        
        for (i = 4; i < WIDTH; i = i + 1) begin : gen_level3
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate
    
    // 计算进位信号
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            assign c[i+1] = g3[i];
        end
    endgenerate
    
    // 计算结果（在这里直接输出p0以实现OR功能）
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_output
            assign y[i] = p0[i];
        end
    endgenerate
endmodule