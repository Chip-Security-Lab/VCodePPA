//SystemVerilog
module Timer_WindowCompare (
    input clk, rst_n, en,
    input [7:0] low_th, high_th,
    output reg in_window
);
    reg [7:0] timer;
    wire in_range;
    wire [7:0] timer_next;
    
    // 优化的比较逻辑，使用单个范围检查
    assign in_range = (timer >= low_th) && (timer <= high_th);
    
    // 使用并行前缀加法器替代传统加法
    ParallelPrefixAdder adder_inst (
        .a(timer),
        .b(8'h1),
        .sum(timer_next)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 8'h0;
            in_window <= 1'b0;
        end else if (en) begin
            timer <= timer_next;
            in_window <= in_range;
        end
    end
endmodule

// 并行前缀加法器模块
module ParallelPrefixAdder (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    // 生成信号
    wire [7:0] g;
    // 传播信号
    wire [7:0] p;
    // 进位信号
    wire [7:0] c;
    
    // 第一级：生成初始的生成和传播信号
    assign g = a & b;
    assign p = a ^ b;
    
    // 第二级：计算每一位的进位信号 (使用Kogge-Stone算法)
    // Level 1
    wire [7:0] g_l1, p_l1;
    assign g_l1[0] = g[0];
    assign p_l1[0] = p[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_level1
            assign g_l1[i] = g[i] | (p[i] & g[i-1]);
            assign p_l1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Level 2
    wire [7:0] g_l2, p_l2;
    assign g_l2[0] = g_l1[0];
    assign p_l2[0] = p_l1[0];
    assign g_l2[1] = g_l1[1];
    assign p_l2[1] = p_l1[1];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin : gen_level2
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
        end
    endgenerate
    
    // Level 3
    wire [7:0] g_l3, p_l3;
    assign g_l3[0] = g_l2[0];
    assign p_l3[0] = p_l2[0];
    assign g_l3[1] = g_l2[1];
    assign p_l3[1] = p_l2[1];
    assign g_l3[2] = g_l2[2];
    assign p_l3[2] = p_l2[2];
    assign g_l3[3] = g_l2[3];
    assign p_l3[3] = p_l2[3];
    
    generate
        for (i = 4; i < 8; i = i + 1) begin : gen_level3
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
            assign p_l3[i] = p_l2[i] & p_l2[i-4];
        end
    endgenerate
    
    // 分配进位信号
    assign c[0] = 1'b0; // 初始进位为0
    assign c[7:1] = g_l3[6:0];
    
    // 计算最终的和
    assign sum = p ^ c;
endmodule