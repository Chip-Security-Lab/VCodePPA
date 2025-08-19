//SystemVerilog
module window_comparator_range_detector(
    input wire [9:0] analog_value,
    input wire [9:0] window_center,
    input wire [9:0] window_width,
    output wire in_window
);
    wire [9:0] half_width;
    wire [9:0] lower_threshold;
    wire [9:0] upper_threshold;
    
    // 使用移位运算计算半宽度
    assign half_width = window_width >> 1;
    
    // 使用并行前缀加法器计算上下阈值
    parallel_prefix_adder lower_adder(
        .a(window_center),
        .b(~half_width + 1'b1), // 二进制补码表示 -half_width
        .sum(lower_threshold)
    );
    
    parallel_prefix_adder upper_adder(
        .a(window_center),
        .b(half_width),
        .sum(upper_threshold)
    );
    
    // 判断是否在窗口范围内
    assign in_window = (analog_value >= lower_threshold) && 
                       (analog_value <= upper_threshold);
endmodule

// 并行前缀加法器模块实现 (10位)
module parallel_prefix_adder(
    input wire [9:0] a,
    input wire [9:0] b,
    output wire [9:0] sum
);
    // 产生和传播信号
    wire [9:0] g; // 产生信号
    wire [9:0] p; // 传播信号
    wire [9:0] c; // 进位信号
    
    // 第一级：计算初始产生和传播信号
    assign g = a & b;
    assign p = a ^ b;
    
    // 第二级：计算每一位的进位
    // 使用Kogge-Stone并行前缀结构
    
    // 第一阶段前缀计算
    wire [9:0] g_l1, p_l1;
    assign g_l1[0] = g[0];
    assign p_l1[0] = p[0];
    
    genvar i;
    generate
        for (i = 1; i < 10; i = i + 1) begin : prefix_level1
            assign g_l1[i] = g[i] | (p[i] & g[i-1]);
            assign p_l1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // 第二阶段前缀计算
    wire [9:0] g_l2, p_l2;
    assign g_l2[0] = g_l1[0];
    assign p_l2[0] = p_l1[0];
    assign g_l2[1] = g_l1[1];
    assign p_l2[1] = p_l1[1];
    
    generate
        for (i = 2; i < 10; i = i + 1) begin : prefix_level2
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
        end
    endgenerate
    
    // 第三阶段前缀计算
    wire [9:0] g_l3, p_l3;
    assign g_l3[0] = g_l2[0];
    assign p_l3[0] = p_l2[0];
    assign g_l3[1] = g_l2[1];
    assign p_l3[1] = p_l2[1];
    assign g_l3[2] = g_l2[2];
    assign p_l3[2] = p_l2[2];
    assign g_l3[3] = g_l2[3];
    assign p_l3[3] = p_l2[3];
    
    generate
        for (i = 4; i < 10; i = i + 1) begin : prefix_level3
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
            assign p_l3[i] = p_l2[i] & p_l2[i-4];
        end
    endgenerate
    
    // 第四阶段前缀计算 (仅适用于位宽10)
    wire [9:0] g_l4, p_l4;
    
    generate
        for (i = 0; i < 8; i = i + 1) begin : prefix_level4_lower
            assign g_l4[i] = g_l3[i];
            assign p_l4[i] = p_l3[i];
        end
        
        for (i = 8; i < 10; i = i + 1) begin : prefix_level4_upper
            assign g_l4[i] = g_l3[i] | (p_l3[i] & g_l3[i-8]);
            assign p_l4[i] = p_l3[i] & p_l3[i-8];
        end
    endgenerate
    
    // 计算进位
    assign c[0] = 1'b0; // 初始无进位
    assign c[9:1] = g_l4[8:0];
    
    // 计算最终和
    assign sum = p ^ c;
endmodule