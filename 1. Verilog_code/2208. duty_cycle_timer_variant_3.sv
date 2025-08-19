//SystemVerilog
module duty_cycle_timer #(
    parameter WIDTH = 12
)(
    input clk,
    input reset,
    input [WIDTH-1:0] period,
    input [7:0] duty_percent, // 0-100%
    output reg pwm_out
);
    reg [WIDTH-1:0] counter;
    wire [WIDTH-1:0] duty_ticks;
    wire [WIDTH-1:0] period_minus_one;
    
    // 并行前缀减法器实现 period - 1
    parallel_prefix_subtractor #(
        .WIDTH(WIDTH)
    ) pps_period_minus_one (
        .a(period),
        .b({{(WIDTH-1){1'b0}}, 1'b1}),
        .diff(period_minus_one)
    );
    
    // Convert percent to ticks
    assign duty_ticks = (period * duty_percent) / 8'd100;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}};
            pwm_out <= 1'b0;
        end else begin
            if (counter >= period_minus_one) begin
                counter <= {WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
            
            if (counter < duty_ticks) begin
                pwm_out <= 1'b1;
            end else begin
                pwm_out <= 1'b0;
            end
        end
    end
endmodule

// 并行前缀减法器模块
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p, g;
    wire [WIDTH-1:0] p_prefix, g_prefix;
    
    // 对减数取反加一（二进制补码）
    assign b_complement = ~b;
    assign carry[0] = 1'b1; // 加1
    
    // 生成传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: prop_gen_stage
            assign p[i] = a[i] | b_complement[i];
            assign g[i] = a[i] & b_complement[i];
        end
    endgenerate
    
    // 并行前缀计算 - 使用Kogge-Stone模式
    // 第一级前缀计算
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: prefix_stage1
            assign p_prefix[i] = p[i];
            assign g_prefix[i] = g[i];
        end
    endgenerate
    
    // 多级并行前缀合并
    wire [WIDTH-1:0] p_temp [0:$clog2(WIDTH)-1];
    wire [WIDTH-1:0] g_temp [0:$clog2(WIDTH)-1];
    
    generate
        // 存储第一级结果
        for (i = 0; i < WIDTH; i = i + 1) begin: store_stage1
            assign p_temp[0][i] = p_prefix[i];
            assign g_temp[0][i] = g_prefix[i];
        end
        
        // 执行log2(WIDTH)级前缀合并
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin: prefix_level
            genvar j;
            for (j = 0; j < WIDTH; j = j + 1) begin: prefix_bit
                if (j >= (1 << i)) begin
                    assign p_temp[i+1][j] = p_temp[i][j] & p_temp[i][j-(1<<i)];
                    assign g_temp[i+1][j] = g_temp[i][j] | (p_temp[i][j] & g_temp[i][j-(1<<i)]);
                end else begin
                    assign p_temp[i+1][j] = p_temp[i][j];
                    assign g_temp[i+1][j] = g_temp[i][j];
                end
            end
        end
    endgenerate
    
    // 计算进位
    generate
        for (i = 1; i <= WIDTH; i = i + 1) begin: carry_gen
            if (i == 1) begin
                assign carry[i] = g[i-1] | (p[i-1] & carry[0]);
            end else begin
                assign carry[i] = g_temp[$clog2(WIDTH)-1][i-1];
            end
        end
    endgenerate
    
    // 计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: diff_gen
            assign diff[i] = a[i] ^ b_complement[i] ^ carry[i];
        end
    endgenerate
endmodule