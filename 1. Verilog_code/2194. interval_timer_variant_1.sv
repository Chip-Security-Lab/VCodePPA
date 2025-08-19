//SystemVerilog
module interval_timer (
    input wire clk,
    input wire rst,
    input wire program_en,
    input wire [7:0] interval_data,
    input wire [3:0] interval_sel,
    output reg event_trigger
);
    reg [7:0] intervals [0:15];
    reg [7:0] current_count;
    reg [3:0] active_interval;
    
    // Han-Carlson加法器输出信号
    wire [7:0] next_count;
    wire [7:0] next_active_interval;
    
    // Han-Carlson加法器实现 - 计数器加1
    han_carlson_adder #(.WIDTH(8)) counter_adder (
        .a(current_count),
        .b(8'd1),
        .cin(1'b0),
        .sum(next_count)
    );
    
    // Han-Carlson加法器实现 - 间隔选择器加1
    han_carlson_adder #(.WIDTH(4)) interval_adder (
        .a(active_interval),
        .b(4'd1),
        .cin(1'b0),
        .sum(next_active_interval[3:0])
    );
    
    assign next_active_interval[7:4] = 4'd0;
    
    always @(posedge clk) begin
        if (rst) begin
            current_count <= 8'd0;
            event_trigger <= 1'b0;
            active_interval <= 4'd0;
        end else if (program_en) begin
            intervals[interval_sel] <= interval_data;
        end else begin
            if (current_count >= intervals[active_interval]) begin
                current_count <= 8'd0;
                event_trigger <= 1'b1;
                active_interval <= next_active_interval[3:0];
            end else begin
                current_count <= next_count;
                event_trigger <= 1'b0;
            end
        end
    end
endmodule

// Han-Carlson加法器模块
module han_carlson_adder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum
);
    // 第一阶段：生成传播(p)和生成(g)信号
    wire [WIDTH-1:0] p, g;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: pg_gen
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // 第二阶段：生成前缀运算的中间信号
    // Han-Carlson算法处理奇数位和偶数位
    wire [WIDTH:0] pp, gg; // 预处理信号
    
    // 初始化
    assign pp[0] = cin;
    assign gg[0] = cin;
    
    // 第一级前缀计算
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: prefix_level1
            assign pp[i+1] = p[i];
            assign gg[i+1] = g[i] | (p[i] & pp[i]);
        end
    endgenerate
    
    // Han-Carlson中间级前缀计算
    // 处理偶数位位置
    wire [WIDTH:0] pp_even, gg_even;
    
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin: init_even
            if (i % 2 == 0) begin
                assign pp_even[i] = pp[i];
                assign gg_even[i] = gg[i];
            end
        end
    endgenerate
    
    // 执行log2(WIDTH/2)级前缀合并
    localparam LEVELS = $clog2(WIDTH/2);
    
    wire [WIDTH:0] pp_stage [0:LEVELS];
    wire [WIDTH:0] gg_stage [0:LEVELS];
    
    // 初始化第一级
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin: init_stage
            if (i % 2 == 0) begin
                assign pp_stage[0][i] = pp_even[i];
                assign gg_stage[0][i] = gg_even[i];
            end
        end
    endgenerate
    
    // 中间级前缀计算
    generate
        genvar l, j;
        for (l = 0; l < LEVELS; l = l + 1) begin: prefix_level
            for (j = 0; j <= WIDTH; j = j + 1) begin: prefix_pos
                if ((j % 2 == 0) && (j >= (2 << l))) begin
                    assign pp_stage[l+1][j] = pp_stage[l][j] & pp_stage[l][j-(2<<(l-1))];
                    assign gg_stage[l+1][j] = gg_stage[l][j] | (pp_stage[l][j] & gg_stage[l][j-(2<<(l-1))]);
                end else if (j % 2 == 0) begin
                    assign pp_stage[l+1][j] = pp_stage[l][j];
                    assign gg_stage[l+1][j] = gg_stage[l][j];
                end
            end
        end
    endgenerate
    
    // 奇数位位置的后处理
    wire [WIDTH:0] pp_final, gg_final;
    
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin: post_process
            if (i % 2 == 0) begin
                assign pp_final[i] = pp_stage[LEVELS-1][i];
                assign gg_final[i] = gg_stage[LEVELS-1][i];
            end else begin
                assign pp_final[i] = pp[i] & pp_final[i-1];
                assign gg_final[i] = g[i-1] | (p[i-1] & gg_final[i-1]);
            end
        end
    endgenerate
    
    // 最终计算和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sum_gen
            assign sum[i] = p[i] ^ gg_final[i];
        end
    endgenerate
endmodule