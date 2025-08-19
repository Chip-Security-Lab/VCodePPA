//SystemVerilog
module loadable_counter (
    input wire clk, rst, load, en,
    input wire [3:0] data,
    output reg [3:0] count
);
    wire [3:0] next_count;
    wire [3:0] incremented_value;
    
    // 使用并行前缀加法器(Parallel Prefix Adder)实现加法
    parallel_prefix_adder adder_inst (
        .a(count),
        .b(4'b0001),
        .sum(incremented_value)
    );
    
    // 多路复用器选择下一个计数值
    assign next_count = rst ? 4'b0000 :
                       load ? data :
                        en ? incremented_value :
                            count;
    
    always @(posedge clk) begin
        count <= next_count;
    end
endmodule

// 并行前缀加法器(Kogge-Stone)实现
module parallel_prefix_adder (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] sum
);
    // 生成和传播信号
    wire [3:0] g; // 生成信号
    wire [3:0] p; // 传播信号
    
    // 第一阶段: 计算初始生成和传播
    assign g = a & b;
    assign p = a ^ b;
    
    // 第二阶段: 前缀计算 - 组生成信号
    wire [3:0] g_prefix;
    wire [3:0] p_prefix;
    
    // 第一级前缀计算
    assign g_prefix[0] = g[0];
    assign p_prefix[0] = p[0];
    
    assign g_prefix[1] = g[1] | (p[1] & g[0]);
    assign p_prefix[1] = p[1] & p[0];
    
    assign g_prefix[2] = g[2] | (p[2] & g_prefix[1]);
    assign p_prefix[2] = p[2] & p_prefix[1];
    
    assign g_prefix[3] = g[3] | (p[3] & g_prefix[2]);
    assign p_prefix[3] = p[3] & p_prefix[2];
    
    // 第三阶段: 计算进位
    wire [3:0] c;
    assign c[0] = 0; // 初始进位为0
    assign c[1] = g[0];
    assign c[2] = g_prefix[1];
    assign c[3] = g_prefix[2];
    wire c_out = g_prefix[3]; // 进位输出(如果需要)
    
    // 第四阶段: 计算最终和
    assign sum = p ^ {c[3:0]};
endmodule