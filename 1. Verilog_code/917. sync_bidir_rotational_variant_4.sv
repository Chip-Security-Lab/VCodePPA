//SystemVerilog
module sync_bidir_rotational #(
    parameter WIDTH = 64
)(
    input                   clock,
    input                   reset,
    input      [WIDTH-1:0]  in_vector,
    input      [WIDTH-1:0]  subtrahend,    // 新增：减数输入
    input      [$clog2(WIDTH)-1:0] shift_count,
    input                   direction, // 0=left, 1=right
    input                   op_sel,    // 新增：0=旋转, 1=减法
    output reg [WIDTH-1:0]  out_vector
);
    wire [WIDTH-1:0] left_rot, right_rot;
    wire [WIDTH-1:0] diff_result;
    
    // 旋转移位操作保持不变
    // 左移结合右侧环绕位
    assign left_rot = (in_vector << shift_count) | (in_vector >> (WIDTH - shift_count));
    
    // 右移结合左侧环绕位
    assign right_rot = (in_vector >> shift_count) | (in_vector << (WIDTH - shift_count));
    
    // 8位并行前缀减法器实现
    parallel_prefix_subtractor #(
        .WIDTH(8)
    ) subtractor_inst (
        .minuend(in_vector[7:0]),
        .subtrahend(subtrahend[7:0]),
        .difference(diff_result[7:0])
    );
    
    // 对于宽度大于8位的情况，高位保持不变
    generate
        if (WIDTH > 8) begin
            assign diff_result[WIDTH-1:8] = in_vector[WIDTH-1:8];
        end
    endgenerate
    
    // 寄存器输出控制逻辑
    always @(posedge clock) begin
        if (reset)
            out_vector <= 0;
        else if (op_sel)
            out_vector <= diff_result;
        else
            out_vector <= direction ? right_rot : left_rot;
    end
endmodule

// 8位并行前缀减法器模块
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] minuend,      // 被减数
    input  [WIDTH-1:0] subtrahend,   // 减数
    output [WIDTH-1:0] difference    // 差
);
    // 内部信号定义
    wire [WIDTH-1:0] negated_subtrahend;
    wire [WIDTH-1:0] p;              // 传播信号
    wire [WIDTH-1:0] g;              // 生成信号
    wire [WIDTH:0] carry;            // 进位信号
    
    // 对减数取反加1（二进制补码）
    assign negated_subtrahend = ~subtrahend;
    
    // 初始进位设为1（用于减数的补码表示）
    assign carry[0] = 1'b1;
    
    // 第一级：计算传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = minuend[i] ^ negated_subtrahend[i];
            assign g[i] = minuend[i] & negated_subtrahend[i];
        end
    endgenerate
    
    // 第二级：前缀并行进位计算（Kogge-Stone算法）
    wire [WIDTH-1:0] pp[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] gg[0:$clog2(WIDTH)];
    
    // 初始化第0级
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_pg
            assign pp[0][i] = p[i];
            assign gg[0][i] = g[i];
        end
    endgenerate
    
    // 构建前缀树
    genvar j, k;
    generate
        for (j = 0; j < $clog2(WIDTH); j = j + 1) begin: prefix_level
            for (k = 0; k < WIDTH; k = k + 1) begin: prefix_bit
                if (k >= (1 << j)) begin
                    assign gg[j+1][k] = gg[j][k] | (pp[j][k] & gg[j][k-(1<<j)]);
                    assign pp[j+1][k] = pp[j][k] & pp[j][k-(1<<j)];
                end else begin
                    assign gg[j+1][k] = gg[j][k];
                    assign pp[j+1][k] = pp[j][k];
                end
            end
        end
    endgenerate
    
    // 最终级：计算进位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            assign carry[i+1] = (i == 0) ? gg[$clog2(WIDTH)][i] | (pp[$clog2(WIDTH)][i] & carry[0]) : 
                                           gg[$clog2(WIDTH)][i] | (pp[$clog2(WIDTH)][i] & carry[i]);
        end
    endgenerate
    
    // 计算最终差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_diff
            assign difference[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule