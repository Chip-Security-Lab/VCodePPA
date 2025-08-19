//SystemVerilog
module RangeDetector_MultiChannel #(
    parameter WIDTH = 8,
    parameter CHANNELS = 4
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] thresholds [CHANNELS*2-1:0],
    input [$clog2(CHANNELS)-1:0] ch_sel,
    output reg out_flag
);

    wire [WIDTH-1:0] lower_threshold;
    wire [WIDTH-1:0] upper_threshold;
    wire [WIDTH-1:0] lower_diff;
    wire [WIDTH-1:0] upper_diff;
    wire lower_ge;
    wire upper_le;
    
    // 选择当前通道的阈值
    assign lower_threshold = thresholds[ch_sel*2];
    assign upper_threshold = thresholds[ch_sel*2+1];
    
    // 使用并行前缀加法器实现减法
    parallel_prefix_adder #(.WIDTH(WIDTH)) lower_adder (
        .a(data_in),
        .b(~lower_threshold + 1'b1),
        .sum(lower_diff)
    );
    
    parallel_prefix_adder #(.WIDTH(WIDTH)) upper_adder (
        .a(upper_threshold),
        .b(~data_in + 1'b1),
        .sum(upper_diff)
    );
    
    // 比较结果
    assign lower_ge = ~lower_diff[WIDTH-1];
    assign upper_le = ~upper_diff[WIDTH-1];
    
    always @(posedge clk) begin
        out_flag <= lower_ge && upper_le;
    end

endmodule

// 并行前缀加法器模块
module parallel_prefix_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);

    // 生成和传播信号
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] carry;
    
    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // 并行前缀计算
    wire [WIDTH-1:0][WIDTH-1:0] g_prefix, p_prefix;
    
    // 初始化
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : init_prefix
            assign g_prefix[0][j] = g[j];
            assign p_prefix[0][j] = p[j];
        end
    endgenerate
    
    // 并行前缀树
    genvar k, m;
    generate
        for (k = 1; k <= $clog2(WIDTH); k = k + 1) begin : prefix_level
            for (m = 0; m < WIDTH; m = m + 1) begin : prefix_element
                if (m < (1 << (k-1))) begin
                    // 不需要更新的位置
                    assign g_prefix[k][m] = g_prefix[k-1][m];
                    assign p_prefix[k][m] = p_prefix[k-1][m];
                end else begin
                    // 更新位置
                    assign g_prefix[k][m] = g_prefix[k-1][m] | (p_prefix[k-1][m] & g_prefix[k-1][m-(1<<(k-1))]);
                    assign p_prefix[k][m] = p_prefix[k-1][m] & p_prefix[k-1][m-(1<<(k-1))];
                end
            end
        end
    endgenerate
    
    // 计算进位
    assign carry[0] = 1'b0; // 初始进位为0
    genvar n;
    generate
        for (n = 1; n < WIDTH; n = n + 1) begin : carry_gen
            assign carry[n] = g_prefix[$clog2(WIDTH)][n-1];
        end
    endgenerate
    
    // 计算最终和
    genvar o;
    generate
        for (o = 0; o < WIDTH; o = o + 1) begin : sum_gen
            assign sum[o] = p[o] ^ carry[o];
        end
    endgenerate

endmodule