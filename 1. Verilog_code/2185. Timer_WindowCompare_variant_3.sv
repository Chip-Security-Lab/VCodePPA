//SystemVerilog
// SystemVerilog
module Timer_WindowCompare (
    input clk, rst_n, en,
    input [7:0] low_th, high_th,
    output reg in_window
);
    reg [7:0] timer;
    wire [7:0] next_timer;
    reg [7:0] reg_low_th, reg_high_th;
    
    // 使用Kogge-Stone加法器计算timer+1
    KoggeStoneAdder #(
        .WIDTH(8)
    ) adder (
        .a(timer),
        .b(8'd1),
        .sum(next_timer)
    );
    
    // 添加输入端寄存器对阈值进行重定时
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_low_th <= 8'b0;
            reg_high_th <= 8'b0;
        end else if (en) begin
            reg_low_th <= low_th;
            reg_high_th <= high_th;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 8'b0;
            in_window <= 1'b0;
        end else if (en) begin
            timer <= next_timer;
            // 使用寄存器化的阈值进行比较
            in_window <= (timer >= reg_low_th) && (timer <= reg_high_th);
        end
    end
endmodule

module KoggeStoneAdder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] p, g; // 生成(generate)和传播(propagate)信号
    wire [WIDTH-1:0] c; // 进位信号
    
    // 第一阶段：计算初始的生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = a[i] ^ b[i]; // 传播
            assign g[i] = a[i] & b[i]; // 生成
        end
    endgenerate
    
    // Kogge-Stone前缀树网络计算进位
    wire [WIDTH-1:0] p_st[0:3]; // 存储中间传播结果
    wire [WIDTH-1:0] g_st[0:3]; // 存储中间生成结果
    
    // 复制第一级的p和g
    assign p_st[0] = p;
    assign g_st[0] = g;
    
    // 进行log2(WIDTH)次迭代来计算各位的进位
    generate
        // 第1级: 距离1
        for (i = 1; i < WIDTH; i = i + 1) begin : stage_0
            assign p_st[1][i] = p_st[0][i] & p_st[0][i-1];
            assign g_st[1][i] = g_st[0][i] | (p_st[0][i] & g_st[0][i-1]);
        end
        assign p_st[1][0] = p_st[0][0];
        assign g_st[1][0] = g_st[0][0];
        
        // 第2级: 距离2
        for (i = 2; i < WIDTH; i = i + 1) begin : stage_1
            assign p_st[2][i] = p_st[1][i] & p_st[1][i-2];
            assign g_st[2][i] = g_st[1][i] | (p_st[1][i] & g_st[1][i-2]);
        end
        for (i = 0; i < 2; i = i + 1) begin : stage_1_copy
            assign p_st[2][i] = p_st[1][i];
            assign g_st[2][i] = g_st[1][i];
        end
        
        // 第3级: 距离4
        for (i = 4; i < WIDTH; i = i + 1) begin : stage_2
            assign p_st[3][i] = p_st[2][i] & p_st[2][i-4];
            assign g_st[3][i] = g_st[2][i] | (p_st[2][i] & g_st[2][i-4]);
        end
        for (i = 0; i < 4; i = i + 1) begin : stage_2_copy
            assign p_st[3][i] = p_st[2][i];
            assign g_st[3][i] = g_st[2][i];
        end
    endgenerate
    
    // 计算最终进位
    assign c[0] = 0; // 初始进位为0
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : final_carry
            assign c[i] = g_st[3][i-1];
        end
    endgenerate
    
    // 计算最终和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : final_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule