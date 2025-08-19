//SystemVerilog
// 顶层模块：程序范围解码器
module program_range_decoder (
    input [7:0] addr,        // 输入地址
    input [7:0] base_addr,   // 基地址
    input [7:0] limit,       // 限制值
    output in_range          // 范围内标志
);
    wire [7:0] upper_bound;  // 上界计算结果
    wire comp_lower_result;  // 下界比较结果
    wire comp_upper_result;  // 上界比较结果

    // 计算上界的子模块
    addr_bound_calculator u_bound_calc (
        .base_addr  (base_addr),
        .limit      (limit),
        .upper_bound(upper_bound)
    );
    
    // 比较器子模块 - 检查地址是否大于等于基地址
    address_comparator u_lower_comp (
        .addr1      (addr),
        .addr2      (base_addr),
        .greater_eq (comp_lower_result),
        .less_than  ()  // 未使用
    );

    // 比较器子模块 - 检查地址是否小于上界
    address_comparator u_upper_comp (
        .addr1      (addr),
        .addr2      (upper_bound),
        .greater_eq (),  // 未使用
        .less_than  (comp_upper_result)
    );
    
    // 范围验证器子模块 - 组合两个比较结果
    range_validator u_validator (
        .lower_check(comp_lower_result),
        .upper_check(comp_upper_result),
        .in_range   (in_range)
    );
endmodule

// 子模块：地址边界计算器（使用Han-Carlson加法器）
module addr_bound_calculator (
    input  [7:0] base_addr,   // 基地址
    input  [7:0] limit,       // 限制值
    output [7:0] upper_bound  // 计算出的上界
);
    // 使用Han-Carlson加法器实现
    han_carlson_adder adder_inst (
        .a(base_addr),
        .b(limit),
        .sum(upper_bound)
    );
endmodule

// Han-Carlson加法器实现（8位）
module han_carlson_adder (
    input  [7:0] a,    // 第一个操作数
    input  [7:0] b,    // 第二个操作数
    output [7:0] sum   // 和
);
    // 阶段1: 预处理阶段 - 生成传播和生成信号
    wire [7:0] p, g;
    
    // 生成传播信号p和生成信号g
    assign p = a ^ b;
    assign g = a & b;
    
    // 阶段2: 前缀计算阶段 - Han-Carlson算法
    // 采用分组前缀结构，延迟为O(log n)
    wire [7:0] pp, gg;  // 第一级传播和生成信号
    wire [7:0] pp_final, gg_final;  // 最终传播和生成信号
    
    // 初始值
    assign pp[0] = p[0];
    assign gg[0] = g[0];
    
    // 第一阶段: 奇数位处理
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 2) begin : odd_stage
            assign pp[i] = p[i];
            assign gg[i] = g[i];
        end
    endgenerate
    
    // 第二阶段: 偶数位处理 (除位置0)
    generate
        for (i = 2; i < 8; i = i + 2) begin : even_stage
            assign pp[i] = p[i] & p[i-1];
            assign gg[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate
    
    // 第三阶段: 前缀树合并
    // 第一级前缀树
    wire [7:0] pp_l1, gg_l1;
    
    // 奇数位更新
    generate
        for (i = 1; i < 8; i = i + 2) begin : prefix_odd
            if (i+2 < 8) begin
                assign pp_l1[i] = pp[i] & pp[i+1];
                assign gg_l1[i] = gg[i] | (pp[i] & gg[i+1]);
            end
            else begin
                assign pp_l1[i] = pp[i];
                assign gg_l1[i] = gg[i];
            end
        end
    endgenerate
    
    // 偶数位无变化
    generate
        for (i = 0; i < 8; i = i + 2) begin : prefix_even_l1
            assign pp_l1[i] = pp[i];
            assign gg_l1[i] = gg[i];
        end
    endgenerate
    
    // 第二级前缀树
    wire [7:0] pp_l2, gg_l2;
    
    // 奇数位更新
    generate
        for (i = 1; i < 8; i = i + 2) begin : prefix_odd_l2
            if (i+4 < 8) begin
                assign pp_l2[i] = pp_l1[i] & pp_l1[i+2];
                assign gg_l2[i] = gg_l1[i] | (pp_l1[i] & gg_l1[i+2]);
            end
            else begin
                assign pp_l2[i] = pp_l1[i];
                assign gg_l2[i] = gg_l1[i];
            end
        end
    endgenerate
    
    // 偶数位无变化
    generate
        for (i = 0; i < 8; i = i + 2) begin : prefix_even_l2
            assign pp_l2[i] = pp_l1[i];
            assign gg_l2[i] = gg_l1[i];
        end
    endgenerate
    
    // 第四阶段: 后处理 - 恢复偶数位的进位信号
    wire [7:0] carry;
    
    // 位置0的进位始终为0
    assign carry[0] = 0;
    
    // 奇数位进位直接来自前缀树
    generate
        for (i = 1; i < 8; i = i + 2) begin : post_odd
            assign carry[i] = gg_l2[i-1];
        end
    endgenerate
    
    // 偶数位进位需要额外计算 (除位置0)
    generate
        for (i = 2; i < 8; i = i + 2) begin : post_even
            assign carry[i] = gg_l2[i-1];
        end
    endgenerate
    
    // 阶段5: 最终求和
    assign sum = p ^ {carry[7:1], 1'b0};
endmodule

// 子模块：地址比较器
module address_comparator (
    input  [7:0] addr1,     // 第一个地址
    input  [7:0] addr2,     // 第二个地址
    output       greater_eq, // addr1 >= addr2
    output       less_than   // addr1 < addr2
);
    // 执行比较操作
    assign greater_eq = (addr1 >= addr2);
    assign less_than = (addr1 < addr2);
endmodule

// 子模块：范围验证器
module range_validator (
    input  lower_check, // 下界检查结果
    input  upper_check, // 上界检查结果
    output in_range     // 最终范围检查结果
);
    // 只有当地址大于等于基地址且小于上界时才在范围内
    assign in_range = lower_check && upper_check;
endmodule