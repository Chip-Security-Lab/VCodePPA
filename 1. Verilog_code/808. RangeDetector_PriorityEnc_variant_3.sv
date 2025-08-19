//SystemVerilog
module RangeDetector_PriorityEnc #(
    parameter WIDTH = 8,
    parameter ZONES = 4
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] zone_limits [ZONES:0],
    output reg [$clog2(ZONES)-1:0] zone_num
);
    integer i;
    wire [WIDTH-1:0] comparison_results [ZONES-1:0];
    
    // 生成比较结果
    genvar g;
    generate
        for (g = 0; g < ZONES; g = g + 1) begin: zone_compare
            HC_Comparator #(
                .WIDTH(WIDTH)
            ) comparator_inst (
                .a(data_in),
                .lower_limit(zone_limits[g]),
                .upper_limit(zone_limits[g+1]),
                .in_range(comparison_results[g])
            );
        end
    endgenerate
    
    // 基于比较结果确定区域
    always @(*) begin
        zone_num = 0;
        for(i = 0; i < ZONES; i = i+1) begin
            if(comparison_results[i][0]) begin
                zone_num = i;
            end
        end
    end
endmodule

// Han-Carlson基于的比较器模块
module HC_Comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] lower_limit,
    input [WIDTH-1:0] upper_limit,
    output [WIDTH-1:0] in_range
);
    wire [WIDTH-1:0] greater_equal, less_than;
    
    // 使用Han-Carlson加法器实现比较功能
    HC_Adder #(
        .WIDTH(WIDTH)
    ) greater_equal_check (
        .a(a),
        .b(~lower_limit),
        .cin(1'b1),
        .sum(),
        .cout(greater_equal[0])
    );
    
    HC_Adder #(
        .WIDTH(WIDTH)
    ) less_than_check (
        .a(~a),
        .b(upper_limit),
        .cin(1'b1),
        .sum(),
        .cout(less_than[0])
    );
    
    assign in_range[0] = greater_equal[0] & less_than[0];
    
    // 扩展结果到整个位宽(为了保持接口一致)
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin: extend_result
            assign in_range[i] = in_range[0];
        end
    endgenerate
endmodule

// Han-Carlson加法器实现
module HC_Adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // 生成和传播信号
    wire [WIDTH-1:0] p, g;
    // 组群生成和传播信号
    wire [WIDTH-1:0] pg, gg;
    wire [WIDTH:0] carries;
    
    // 第一阶段：计算初始生成和传播
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: stage1
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // 设置初始进位
    assign carries[0] = cin;
    
    // 第二阶段：Han-Carlson预处理 - 偶数位置
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin: stage2_even
            assign pg[i] = p[i];
            assign gg[i] = g[i];
        end
    endgenerate
    
    // 第三阶段：Han-Carlson并行前缀计算 - 奇数位置
    generate
        for (i = 1; i < WIDTH; i = i + 2) begin: stage2_odd
            assign pg[i] = p[i] & p[i-1];
            assign gg[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate
    
    // 第一级树结构处理
    wire [WIDTH-1:0] pg_l1, gg_l1;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: tree_level1
            if (i < 2) begin
                assign pg_l1[i] = pg[i];
                assign gg_l1[i] = gg[i];
            end else begin
                assign pg_l1[i] = pg[i] & pg[i-2];
                assign gg_l1[i] = gg[i] | (pg[i] & gg[i-2]);
            end
        end
    endgenerate
    
    // 第二级树结构处理
    wire [WIDTH-1:0] pg_l2, gg_l2;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: tree_level2
            if (i < 4) begin
                assign pg_l2[i] = pg_l1[i];
                assign gg_l2[i] = gg_l1[i];
            end else begin
                assign pg_l2[i] = pg_l1[i] & pg_l1[i-4];
                assign gg_l2[i] = gg_l1[i] | (pg_l1[i] & gg_l1[i-4]);
            end
        end
    endgenerate
    
    // 第三级树结构处理
    wire [WIDTH-1:0] pg_l3, gg_l3;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: tree_level3
            if (i < 8) begin
                assign pg_l3[i] = pg_l2[i];
                assign gg_l3[i] = gg_l2[i];
            end else begin
                assign pg_l3[i] = pg_l2[i] & pg_l2[i-8];
                assign gg_l3[i] = gg_l2[i] | (pg_l2[i] & gg_l2[i-8]);
            end
        end
    endgenerate
    
    // 进位计算
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: carry_compute
            if (i == 0) begin
                assign carries[i+1] = gg_l3[i] | (pg_l3[i] & cin);
            end else begin
                assign carries[i+1] = gg_l3[i] | (pg_l3[i] & carries[i]);
            end
        end
    endgenerate
    
    // 最终和计算
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sum_compute
            assign sum[i] = p[i] ^ carries[i];
        end
    endgenerate
    
    // 输出进位
    assign cout = carries[WIDTH];
endmodule