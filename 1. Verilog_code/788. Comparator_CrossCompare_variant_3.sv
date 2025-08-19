//SystemVerilog
module Comparator_CrossCompare #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] a0, b0, a1, b1, // 两组输入对
    output             eq0, eq1,       // 独立比较结果
    output             all_eq          // 全等信号
);
    // 实例化两个单比较器模块
    SingleComparator #(.WIDTH(WIDTH)) comparator0 (
        .a(a0),
        .b(b0),
        .eq(eq0)
    );
    
    SingleComparator #(.WIDTH(WIDTH)) comparator1 (
        .a(a1),
        .b(b1),
        .eq(eq1)
    );
    
    // 实例化结果合并模块
    ResultCombiner result_combiner (
        .eq0(eq0),
        .eq1(eq1),
        .all_eq(all_eq)
    );
endmodule

// 单个比较器子模块 - 使用条件求和比较算法
module SingleComparator #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] a, b,
    output             eq
);
    // 内部信号声明
    wire [WIDTH-1:0] match;      // 每一位的匹配信号
    wire [WIDTH-1:0] sum;        // 条件求和结果
    
    // 生成每一位的匹配信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: bit_matcher
            assign match[i] = (a[i] == b[i]);
        end
    endgenerate
    
    // 条件求和比较算法实现
    // 第一级：2位一组求和
    wire [WIDTH/2-1:0] sum_level1;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin: level1
            assign sum_level1[i] = match[2*i] & match[2*i+1];
        end
    endgenerate
    
    // 第二级：4位一组求和
    wire [WIDTH/4-1:0] sum_level2;
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin: level2
            assign sum_level2[i] = sum_level1[2*i] & sum_level1[2*i+1];
        end
    endgenerate
    
    // 第三级：8位一组求和
    wire [WIDTH/8-1:0] sum_level3;
    generate
        for (i = 0; i < WIDTH/8; i = i + 1) begin: level3
            assign sum_level3[i] = sum_level2[2*i] & sum_level2[2*i+1];
        end
    endgenerate
    
    // 第四级：16位一组求和
    wire [WIDTH/16-1:0] sum_level4;
    generate
        for (i = 0; i < WIDTH/16; i = i + 1) begin: level4
            assign sum_level4[i] = sum_level3[2*i] & sum_level3[2*i+1];
        end
    endgenerate
    
    // 最终结果：所有位都匹配
    assign eq = &match;
endmodule

// 结果合并子模块
module ResultCombiner (
    input  eq0, eq1,
    output all_eq
);
    // 使用布尔逻辑合并结果
    assign all_eq = eq0 & eq1;
endmodule