//SystemVerilog
module checksum_parity (
    input [31:0] data,         // 输入数据 - 4个8位数据
    input req,                 // 请求信号，替代原来的valid输入
    output reg ack,            // 应答信号，替代原来的ready输出
    output reg [7:0] checksum  // 校验和输出
);
    // 将32位数据分解为4个8位数据
    wire [7:0] data0 = data[7:0];
    wire [7:0] data1 = data[15:8];
    wire [7:0] data2 = data[23:16];
    wire [7:0] data3 = data[31:24];
    
    // 并行前缀加法器实现
    // 第一级：生成8位进位传播和生成信号
    wire [7:0] p0, p1, p2, p3; // 进位传播信号
    wire [7:0] g0, g1, g2, g3; // 进位生成信号
    
    // 为每个8位数据生成基本的进位传播和生成信号
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_pg_signals
            assign p0[i] = data0[i];
            assign g0[i] = 1'b0;
            
            assign p1[i] = data1[i];
            assign g1[i] = 1'b0;
            
            assign p2[i] = data2[i];
            assign g2[i] = 1'b0;
            
            assign p3[i] = data3[i];
            assign g3[i] = 1'b0;
        end
    endgenerate
    
    // 第二级：合并进位网络 - 并行前缀计算
    wire [7:0] sum0, sum1, sum2, sum3;
    wire [2:0] carry; // 存储各级进位
    
    // 第一对数据相加
    parallel_prefix_adder_8bit adder01 (
        .a(data0),
        .b(data1),
        .sum(sum0),
        .cout(carry[0])
    );
    
    // 第二对数据相加
    parallel_prefix_adder_8bit adder23 (
        .a(data2),
        .b(data3),
        .sum(sum1),
        .cout(carry[1])
    );
    
    // 两个部分和相加
    parallel_prefix_adder_8bit adder_final (
        .a(sum0),
        .b(sum1),
        .sum(sum2),
        .cout(carry[2])
    );
    
    // 计算校验和奇偶性
    wire [7:0] final_sum = sum2;
    wire parity = ^final_sum;
    
    // 实现请求-应答握手逻辑
    always @(*) begin
        if (req) begin
            checksum = final_sum;
            ack = 1'b1;        // 收到请求后立即应答
        end else begin
            checksum = 8'b0;
            ack = 1'b0;        // 无请求时无应答
        end
    end
endmodule

// 8位并行前缀加法器子模块
module parallel_prefix_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output cout
);
    // 生成和传播信号
    wire [7:0] g, p;
    
    // 第一级：计算基本的生成和传播信号
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin: gen_gp
            assign g[i] = a[i] & b[i];      // 生成信号
            assign p[i] = a[i] | b[i];      // 传播信号
        end
    endgenerate
    
    // 第二级：前缀计算进位
    wire [7:0] c; // 内部进位信号
    
    // 使用Kogge-Stone并行前缀树计算进位
    // 前缀操作: (g, p) o (g', p') = (g + p·g', p·p')
    
    // 第一级前缀树
    wire [7:0] g_lvl1, p_lvl1;
    
    assign g_lvl1[0] = g[0];
    assign p_lvl1[0] = p[0];
    
    generate
        for (i = 1; i < 8; i = i + 1) begin: gen_prefix_lvl1
            assign g_lvl1[i] = g[i] | (p[i] & g[i-1]);
            assign p_lvl1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // 第二级前缀树
    wire [7:0] g_lvl2, p_lvl2;
    
    assign g_lvl2[0] = g_lvl1[0];
    assign p_lvl2[0] = p_lvl1[0];
    assign g_lvl2[1] = g_lvl1[1];
    assign p_lvl2[1] = p_lvl1[1];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin: gen_prefix_lvl2
            assign g_lvl2[i] = g_lvl1[i] | (p_lvl1[i] & g_lvl1[i-2]);
            assign p_lvl2[i] = p_lvl1[i] & p_lvl1[i-2];
        end
    endgenerate
    
    // 第三级前缀树
    wire [7:0] g_lvl3, p_lvl3;
    
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_prefix_lvl3_first
            assign g_lvl3[i] = g_lvl2[i];
            assign p_lvl3[i] = p_lvl2[i];
        end
        
        for (i = 4; i < 8; i = i + 1) begin: gen_prefix_lvl3_second
            assign g_lvl3[i] = g_lvl2[i] | (p_lvl2[i] & g_lvl2[i-4]);
            assign p_lvl3[i] = p_lvl2[i] & p_lvl2[i-4];
        end
    endgenerate
    
    // 计算进位
    assign c[0] = 1'b0; // 初始进位为0
    
    generate
        for (i = 1; i < 8; i = i + 1) begin: gen_carry
            assign c[i] = g_lvl3[i-1];
        end
    endgenerate
    
    // 计算输出进位
    assign cout = g_lvl3[7];
    
    // 计算和
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_sum
            assign sum[i] = a[i] ^ b[i] ^ c[i];
        end
    endgenerate
endmodule