//SystemVerilog
module counter_reset_gen #(
    parameter THRESHOLD = 10
)(
    input wire clk,
    input wire enable,
    output reg reset_out
);
    reg [3:0] counter;
    
    // 优化比较逻辑，减少关键路径
    wire counter_at_or_above_threshold = (counter >= THRESHOLD);
    wire counter_will_reach_threshold = (counter == THRESHOLD - 1) && enable;
    wire counter_needs_increment = (counter < THRESHOLD) && enable;
    
    // 预计算下一个状态
    wire reset_next = counter_at_or_above_threshold || counter_will_reach_threshold;
    
    // Brent-Kung加法器实现
    wire [3:0] next_counter;
    brent_kung_adder bka(
        .a(counter),
        .b(4'b0001),
        .cin(1'b0),
        .sum(next_counter),
        .cout()
    );
    
    // 更高效的计数器更新逻辑
    always @(posedge clk) begin
        if (!enable)
            counter <= 4'b0;
        else if (counter_needs_increment)
            counter <= next_counter;
        // 当计数器达到阈值时保持不变
            
        // 直接从预计算值更新输出
        reset_out <= reset_next;
    end
endmodule

// Brent-Kung加法器实现
module brent_kung_adder (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire cin,
    output wire [3:0] sum,
    output wire cout
);
    // 内部信号声明
    wire [3:0] p, g; // 传播和生成信号
    wire [3:0] c; // 进位信号
    
    // 第一级：计算基本传播和生成信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 第二级：计算组传播和生成信号（前缀计算树）
    wire [1:0] p_group1, g_group1;
    
    // 二位组计算
    assign p_group1[0] = p[1] & p[0];
    assign g_group1[0] = g[1] | (p[1] & g[0]);
    
    assign p_group1[1] = p[3] & p[2];
    assign g_group1[1] = g[3] | (p[3] & g[2]);
    
    // 四位组计算
    wire p_group2, g_group2;
    assign p_group2 = p_group1[1] & p_group1[0];
    assign g_group2 = g_group1[1] | (p_group1[1] & g_group1[0]);
    
    // 第三级：计算每位的进位
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g_group1[0] | (p_group1[0] & cin);
    assign c[3] = g[2] | (p[2] & g_group1[0]) | (p[2] & p_group1[0] & cin);
    assign cout = g_group2 | (p_group2 & cin);
    
    // 第四级：计算最终的和
    assign sum = p ^ {c[3:1], cin};
endmodule