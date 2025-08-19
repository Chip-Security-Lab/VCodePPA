//SystemVerilog
module incrementers (
    input clk,               // 时钟信号
    input rst_n,             // 复位信号
    input [5:0] base,        // 基础输入值
    output reg [5:0] double, // 双倍输出（流水线）
    output reg [5:0] triple  // 三倍输出（流水线）
);
    // 内部信号定义
    reg [5:0] base_reg;        // 注册基础输入
    reg [5:0] base_shifted;    // 存储移位结果

    // 跳跃进位加法器所需信号
    wire [5:0] p, g;           // 传播和生成信号
    wire [5:0] c;              // 进位信号
    wire [5:0] sum;            // 求和结果
    
    // 第一级流水线 - 注册输入与计算移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_reg <= 6'b0;
            base_shifted <= 6'b0;
        end else begin
            base_reg <= base;            // 注册输入信号
            base_shifted <= base << 1;   // 计算并存储移位结果
        end
    end

    // 跳跃进位加法器逻辑
    // 生成传播和生成信号
    assign p = base_reg ^ base_shifted;   // 传播信号
    assign g = base_reg & base_shifted;   // 生成信号

    // 跳跃进位链
    assign c[0] = 1'b0;  // 初始进位为0
    assign c[1] = g[0];
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & c[1]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & c[1]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | 
                  (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & c[1]);

    // 计算求和
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];

    // 第二级流水线 - 计算最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            double <= 6'b0;
            triple <= 6'b0;
        end else begin
            double <= base_shifted;       // 直接使用之前计算的移位结果
            triple <= sum;                // 使用跳跃进位加法器的结果
        end
    end
endmodule