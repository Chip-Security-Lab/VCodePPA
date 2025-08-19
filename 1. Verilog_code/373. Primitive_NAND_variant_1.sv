//SystemVerilog
// Top-level module
module BrentKung_Adder_8bit #(
    parameter INPUT_STAGES = 1,  // 可配置输入缓冲级数
    parameter OUTPUT_STAGES = 1  // 可配置输出缓冲级数
)(
    input wire [7:0] a,
    input wire [7:0] b,
    input wire cin,
    output wire [7:0] sum,
    output wire cout
);

    // 内部连线
    wire [7:0] a_buffered, b_buffered;
    wire cin_buffered;
    wire [7:0] sum_internal;
    wire cout_internal;
    
    // 实例化输入缓冲子模块
    InputBuffer8bit #(
        .STAGES(INPUT_STAGES)
    ) input_buffer_inst (
        .a(a),
        .b(b),
        .cin(cin),
        .a_out(a_buffered),
        .b_out(b_buffered),
        .cin_out(cin_buffered)
    );
    
    // 实例化Brent-Kung加法器核心子模块
    BrentKungCore adder_core_inst (
        .a(a_buffered),
        .b(b_buffered),
        .cin(cin_buffered),
        .sum(sum_internal),
        .cout(cout_internal)
    );
    
    // 实例化输出缓冲子模块
    OutputBuffer8bit #(
        .STAGES(OUTPUT_STAGES)
    ) output_buffer_inst (
        .sum_in(sum_internal),
        .cout_in(cout_internal),
        .sum_out(sum),
        .cout_out(cout)
    );
    
endmodule

// 输入缓冲子模块
module InputBuffer8bit #(
    parameter STAGES = 1  // 缓冲级数
)(
    input wire [7:0] a,
    input wire [7:0] b,
    input wire cin,
    output wire [7:0] a_out,
    output wire [7:0] b_out,
    output wire cin_out
);
    
    // 内部连线数组
    wire [STAGES:0][7:0] a_buff;
    wire [STAGES:0][7:0] b_buff;
    wire [STAGES:0] cin_buff;
    
    // 输入赋值
    assign a_buff[0] = a;
    assign b_buff[0] = b;
    assign cin_buff[0] = cin;
    
    // 生成缓冲级
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : BUFFER_STAGE
            // 简单缓冲器
            assign a_buff[i+1] = a_buff[i];
            assign b_buff[i+1] = b_buff[i];
            assign cin_buff[i+1] = cin_buff[i];
        end
    endgenerate
    
    // 输出赋值
    assign a_out = a_buff[STAGES];
    assign b_out = b_buff[STAGES];
    assign cin_out = cin_buff[STAGES];
    
endmodule

// Brent-Kung加法器核心子模块
module BrentKungCore (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire cin,
    output wire [7:0] sum,
    output wire cout
);
    
    // 生成和传播信号
    wire [7:0] g, p;
    // 第一级携带信号
    wire [7:0] c;
    
    // 计算各位的生成和传播信号
    assign g[0] = a[0] & b[0];
    assign p[0] = a[0] ^ b[0];
    assign g[1] = a[1] & b[1];
    assign p[1] = a[1] ^ b[1];
    assign g[2] = a[2] & b[2];
    assign p[2] = a[2] ^ b[2];
    assign g[3] = a[3] & b[3];
    assign p[3] = a[3] ^ b[3];
    assign g[4] = a[4] & b[4];
    assign p[4] = a[4] ^ b[4];
    assign g[5] = a[5] & b[5];
    assign p[5] = a[5] ^ b[5];
    assign g[6] = a[6] & b[6];
    assign p[6] = a[6] ^ b[6];
    assign g[7] = a[7] & b[7];
    assign p[7] = a[7] ^ b[7];
    
    // Brent-Kung树结构 - 组合生成和传播信号
    
    // 第一级：计算相邻两位的组合生成和传播
    wire [3:0] g_level1, p_level1;
    
    assign g_level1[0] = g[1] | (p[1] & g[0]);
    assign p_level1[0] = p[1] & p[0];
    
    assign g_level1[1] = g[3] | (p[3] & g[2]);
    assign p_level1[1] = p[3] & p[2];
    
    assign g_level1[2] = g[5] | (p[5] & g[4]);
    assign p_level1[2] = p[5] & p[4];
    
    assign g_level1[3] = g[7] | (p[7] & g[6]);
    assign p_level1[3] = p[7] & p[6];
    
    // 第二级：计算跨越4位的组合生成和传播
    wire [1:0] g_level2, p_level2;
    
    assign g_level2[0] = g_level1[1] | (p_level1[1] & g_level1[0]);
    assign p_level2[0] = p_level1[1] & p_level1[0];
    
    assign g_level2[1] = g_level1[3] | (p_level1[3] & g_level1[2]);
    assign p_level2[1] = p_level1[3] & p_level1[2];
    
    // 第三级：计算跨越8位的组合生成和传播
    wire g_level3, p_level3;
    
    assign g_level3 = g_level2[1] | (p_level2[1] & g_level2[0]);
    assign p_level3 = p_level2[1] & p_level2[0];
    
    // 计算各位的进位信号
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g_level1[0] | (p_level1[0] & cin);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g_level2[0] | (p_level2[0] & cin);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g_level1[2] | (p_level1[2] & c[4]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign cout = g_level3 | (p_level3 & cin);
    
    // 计算和
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
    
endmodule

// 输出缓冲子模块
module OutputBuffer8bit #(
    parameter STAGES = 1  // 缓冲级数
)(
    input wire [7:0] sum_in,
    input wire cout_in,
    output wire [7:0] sum_out,
    output wire cout_out
);
    
    // 内部连线数组
    wire [STAGES:0][7:0] sum_buff;
    wire [STAGES:0] cout_buff;
    
    // 输入赋值
    assign sum_buff[0] = sum_in;
    assign cout_buff[0] = cout_in;
    
    // 生成缓冲级
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : BUFFER_STAGE
            // 简单缓冲器
            assign sum_buff[i+1] = sum_buff[i];
            assign cout_buff[i+1] = cout_buff[i];
        end
    endgenerate
    
    // 输出赋值
    assign sum_out = sum_buff[STAGES];
    assign cout_out = cout_buff[STAGES];
    
endmodule