//SystemVerilog
module hierarchical_intr_ctrl #(
  parameter GROUPS = 4,
  parameter SOURCES_PER_GROUP = 4
)(
  input clk, rst_n,
  input [GROUPS*SOURCES_PER_GROUP-1:0] intr_sources,
  input [GROUPS-1:0] group_mask,
  input [GROUPS*SOURCES_PER_GROUP-1:0] source_masks,
  output reg [$clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)-1:0] intr_id,
  output reg valid
);
    // 预计算masked_sources以减少关键路径
    wire [GROUPS*SOURCES_PER_GROUP-1:0] masked_sources;
    wire [GROUPS-1:0] group_active;
    reg [$clog2(GROUPS)-1:0] highest_group;
    reg [$clog2(SOURCES_PER_GROUP)-1:0] source_ids [0:GROUPS-1];
    reg any_group_active;
    
    // 将掩码操作作为单独的操作，减少后续逻辑延迟
    genvar g, s;
    generate
        for (g = 0; g < GROUPS; g = g + 1) begin : group_gen
            for (s = 0; s < SOURCES_PER_GROUP; s = s + 1) begin : source_gen
                assign masked_sources[g*SOURCES_PER_GROUP+s] = 
                       intr_sources[g*SOURCES_PER_GROUP+s] & source_masks[g*SOURCES_PER_GROUP+s];
            end
            
            // 计算每组是否有活动中断
            wire group_has_intr = |masked_sources[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP];
            // 将组掩码应用为单独步骤
            assign group_active[g] = group_has_intr & group_mask[g];
        end
    endgenerate
    
    // 预先计算是否有任何活动组
    always @* begin
        any_group_active = |group_active;
    end
    
    // 寻找每组内的最高优先级源
    // 使用并行结构来平衡路径
    integer i, j;
    always @* begin
        for (i = 0; i < GROUPS; i = i + 1) begin
            source_ids[i] = 0;
            for (j = 0; j < SOURCES_PER_GROUP; j = j + 1) begin
                // 使用条件赋值替代if语句以平衡路径
                source_ids[i] = masked_sources[i*SOURCES_PER_GROUP+j] ? j[$clog2(SOURCES_PER_GROUP)-1:0] : source_ids[i];
            end
        end
    end
    
    // 使用Kogge-Stone加法器计算最高优先级组
    // 预先定义的位宽
    localparam WIDTH = $clog2(GROUPS);
    
    // Kogge-Stone加法器的中间信号
    wire [WIDTH-1:0] priority_sum;
    wire [WIDTH-1:0] group_index;
    
    // 初始化group_index
    assign group_index = 0;
    
    // Kogge-Stone加法器实现
    ks_adder #(.WIDTH(WIDTH)) group_adder (
        .a(group_index),
        .b(highest_group_finder(group_active)),
        .cin(1'b0),
        .sum(priority_sum)
    );
    
    // 从Kogge-Stone加法器的结果更新highest_group
    always @* begin
        highest_group = priority_sum;
    end
    
    // 寄存输出以减少时序关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_id <= 0;
            valid <= 1'b0;
        end else begin
            valid <= any_group_active;
            intr_id <= {highest_group, source_ids[highest_group]};
        end
    end
    
    // 辅助函数：找到最高优先级组索引
    function [WIDTH-1:0] highest_group_finder;
        input [GROUPS-1:0] active_groups;
        reg [WIDTH-1:0] result;
        integer k;
    begin
        result = 0;
        for (k = 0; k < GROUPS; k = k + 1) begin
            if (active_groups[k])
                result = k[WIDTH-1:0];
        end
        highest_group_finder = result;
    end
    endfunction
endmodule

// Kogge-Stone 加法器模块
module ks_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum
);
    // 生成(G)和传播(P)信号
    wire [WIDTH-1:0] g, p;
    // 中间G和P信号
    wire [WIDTH-1:0] g_temp[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] p_temp[0:$clog2(WIDTH)];
    
    // 第一级: 计算位级生成和传播
    genvar i, j, l;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_stage
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] | b[i];
        end
    endgenerate
    
    // 初始化g_temp和p_temp的第一级
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_gp
            assign g_temp[0][i] = g[i];
            assign p_temp[0][i] = p[i];
        end
    endgenerate
    
    // Kogge-Stone并行前缀计算
    generate
        for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin: prefix_level
            for (j = 0; j < WIDTH; j = j + 1) begin: prefix_cell
                if (j >= (1 << (i-1))) begin
                    assign g_temp[i][j] = g_temp[i-1][j] | (p_temp[i-1][j] & g_temp[i-1][j-(1<<(i-1))]);
                    assign p_temp[i][j] = p_temp[i-1][j] & p_temp[i-1][j-(1<<(i-1))];
                end
                else begin
                    assign g_temp[i][j] = g_temp[i-1][j];
                    assign p_temp[i][j] = p_temp[i-1][j];
                end
            end
        end
    endgenerate
    
    // 最终级：计算和
    wire [WIDTH:0] carry;
    assign carry[0] = cin;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sum_stage
            assign carry[i+1] = g_temp[$clog2(WIDTH)][i] | (p_temp[$clog2(WIDTH)][i] & carry[0]);
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
        end
    endgenerate
endmodule