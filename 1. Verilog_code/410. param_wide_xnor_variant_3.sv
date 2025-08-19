//SystemVerilog
// 顶层模块 - 参数化减法器运算
module param_wide_subtractor #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] A,
    input  [WIDTH-1:0] B,
    output [WIDTH-1:0] Y
);

    // 实例化Brent-Kung减法器子模块
    brentkung_subtractor #(
        .WIDTH(WIDTH)
    ) subtractor_inst (
        .a_in(A),
        .b_in(B),
        .result_out(Y)
    );

endmodule

// 子模块 - 执行Brent-Kung减法运算
module brentkung_subtractor #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a_in,
    input  [WIDTH-1:0] b_in,
    output [WIDTH-1:0] result_out
);

    // Brent-Kung减法器实现
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH-1:0] p, g;
    wire [WIDTH:0] carry;
    
    // 对B取反用于减法
    assign b_complement = ~b_in;
    
    // 设置初始进位为1，用于二进制补码减法
    assign carry[0] = 1'b1;
    
    // 计算初始的生成(g)和传播(p)信号
    assign g = a_in & b_complement;
    assign p = a_in ^ b_complement;
    
    // Brent-Kung进位生成网络 - 第一阶段: 计算(G,P)对
    wire [WIDTH-1:0] g_level1, p_level1;
    wire [WIDTH/2-1:0] g_level2, p_level2;
    wire [WIDTH/4-1:0] g_level3, p_level3;
    
    // 第一级: 2位组合
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : level1_gen
            assign g_level1[2*i] = g[2*i];
            assign p_level1[2*i] = p[2*i];
            
            assign g_level1[2*i+1] = g[2*i+1] | (p[2*i+1] & g[2*i]);
            assign p_level1[2*i+1] = p[2*i+1] & p[2*i];
        end
    endgenerate
    
    // 第二级: 4位组合
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin : level2_gen
            assign g_level2[2*i] = g_level1[4*i+1];
            assign p_level2[2*i] = p_level1[4*i+1];
            
            assign g_level2[2*i+1] = g_level1[4*i+3] | (p_level1[4*i+3] & g_level1[4*i+1]);
            assign p_level2[2*i+1] = p_level1[4*i+3] & p_level1[4*i+1];
        end
    endgenerate
    
    // 第三级: 8位组合
    generate
        if (WIDTH >= 8) begin : level3_gen
            assign g_level3[0] = g_level2[1];
            assign p_level3[0] = p_level2[1];
            
            if (WIDTH > 8) begin
                assign g_level3[1] = g_level2[3] | (p_level2[3] & g_level2[1]);
                assign p_level3[1] = p_level2[3] & p_level2[1];
            end
        end
    endgenerate
    
    // Brent-Kung进位逆向传播 - 计算所有进位
    generate
        // 第一个进位直接来自第一位的生成信号
        assign carry[1] = g[0] | (p[0] & carry[0]);
        
        // 计算位置2处的进位
        assign carry[2] = g_level1[1] | (p_level1[1] & carry[0]);
        
        // 计算位置3处的进位
        assign carry[3] = g[2] | (p[2] & carry[2]);
        
        // 计算位置4处的进位
        assign carry[4] = g_level2[1] | (p_level2[1] & carry[0]);
        
        // 计算位置5处的进位
        assign carry[5] = g[4] | (p[4] & carry[4]);
        
        // 计算位置6处的进位
        assign carry[6] = g_level1[5] | (p_level1[5] & carry[4]);
        
        // 计算位置7处的进位
        assign carry[7] = g[6] | (p[6] & carry[6]);
        
        // 计算位置8处的进位
        if (WIDTH >= 8)
            assign carry[8] = g_level3[0] | (p_level3[0] & carry[0]);
    endgenerate
    
    // 计算最终结果
    assign result_out = p ^ carry[WIDTH-1:0];

endmodule