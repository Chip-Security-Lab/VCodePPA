//SystemVerilog
module counter_reset_gen #(
    parameter THRESHOLD = 10
)(
    input wire clk,
    input wire enable,
    output reg reset_out
);
    reg [3:0] counter;
    wire [3:0] counter_next;
    
    // Han-Carlson加法器实现
    han_carlson_adder adder_inst (
        .a(counter),
        .b(4'b0001),
        .cin(1'b0),
        .sum(counter_next),
        .cout()
    );
    
    always @(posedge clk) begin
        if (!enable)
            counter <= 4'b0;
        else if (counter < THRESHOLD)
            counter <= counter_next;
        
        reset_out <= (counter == THRESHOLD) ? 1'b1 : 1'b0;
    end
endmodule

module han_carlson_adder (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    // 阶段1: 生成传播(P)和生成(G)信号
    wire [3:0] p, g;
    assign p = a ^ b;
    assign g = a & b;
    
    // 阶段2: 前置处理
    wire [4:0] c;
    assign c[0] = cin;
    
    // 阶段3: Han-Carlson进位网络
    // 第一级: 偶数位生成组群进位信号
    wire [1:0] g_even_1;
    wire [1:0] p_even_1;
    
    assign g_even_1[0] = g[0] | (p[0] & c[0]);
    assign g_even_1[1] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    
    assign p_even_1[0] = p[0];
    assign p_even_1[1] = p[2] & p[1] & p[0];
    
    // 第二级: 奇数位进位计算
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g_even_1[0];
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g_even_1[1];
    
    // 阶段4: 计算最终和
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule