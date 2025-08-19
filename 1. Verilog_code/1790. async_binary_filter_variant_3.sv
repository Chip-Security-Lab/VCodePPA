//SystemVerilog
module async_binary_filter #(
    parameter W = 8
)(
    input [W-1:0] analog_in,
    input [W-1:0] threshold,
    output binary_out
);
    wire [W-1:0] difference;
    wire borrow_out;
    
    // 使用并行前缀减法器计算 analog_in - threshold
    parallel_prefix_subtractor #(
        .WIDTH(W)
    ) pps_inst (
        .a(analog_in),
        .b(threshold),
        .diff(difference),
        .borrow_out(borrow_out)
    );
    
    // 如果没有借位，说明 analog_in >= threshold
    assign binary_out = ~borrow_out;
endmodule

module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    // 生成(G)和传播(P)信号
    wire [WIDTH-1:0] p, g;
    
    // 前缀运算的中间结果，每一级都存储所有位置的G和P
    wire [WIDTH-1:0] g_level[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] p_level[0:$clog2(WIDTH)];
    
    // 最终借位信号
    wire [WIDTH:0] borrow;
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 第一级：计算单位传播和生成信号
    genvar i, j, level;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg_init
            assign p[i] = a[i] ^ b[i];         // 传播条件：a和b不同
            assign g[i] = (~a[i]) & b[i];      // 生成借位条件：a小于b
            
            // 第0级的初始化
            assign g_level[0][i] = g[i];
            assign p_level[0][i] = p[i];
        end
    endgenerate
    
    // 并行前缀计算
    generate
        for (level = 0; level < $clog2(WIDTH); level = level + 1) begin : prefix_levels
            for (i = 0; i < WIDTH; i = i + 1) begin : prefix_bits
                if (i >= (1 << level)) begin
                    // 对于每个级别，合并前面的结果
                    assign g_level[level+1][i] = g_level[level][i] | 
                                               (p_level[level][i] & g_level[level][i-(1<<level)]);
                    assign p_level[level+1][i] = p_level[level][i] & p_level[level][i-(1<<level)];
                end else begin
                    // 较低位置保持不变
                    assign g_level[level+1][i] = g_level[level][i];
                    assign p_level[level+1][i] = p_level[level][i];
                end
            end
        end
    endgenerate
    
    // 计算借位和差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow_diff
            if (i == 0) begin
                // 第一位借位直接来自初始借位(0)
                assign borrow[i+1] = g_level[$clog2(WIDTH)][i];
            end else begin
                // 其他位的借位来自前缀计算结果
                assign borrow[i+1] = g_level[$clog2(WIDTH)][i] | 
                                   (p_level[$clog2(WIDTH)][i] & borrow[0]);
            end
            
            // 差值计算
            assign diff[i] = p[i] ^ borrow[i];
        end
    endgenerate
    
    // 最高位借位输出
    assign borrow_out = borrow[WIDTH];
endmodule