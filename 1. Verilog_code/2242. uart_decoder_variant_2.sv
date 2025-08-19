//SystemVerilog
module uart_decoder #(parameter BAUD_RATE=9600) (
    input rx, clk,
    output reg [7:0] data,
    output reg parity_err
);
    reg [3:0] sample_cnt;
    wire mid_sample = (sample_cnt == 4'd7);
    wire [3:0] next_sample_cnt;
    
    // Han-Carlson加法器实现
    han_carlson_adder #(.WIDTH(4)) sample_counter_adder (
        .a(sample_cnt),
        .b(4'b0001),
        .cin(1'b0),
        .sum(next_sample_cnt),
        .cout()
    );
    
    always @(posedge clk) begin
        if(rx && sample_cnt < 15) sample_cnt <= next_sample_cnt;
        else if(mid_sample) begin
            data <= {rx, data[7:1]};
            parity_err <= ^data ^ rx;
        end
    end
endmodule

// Han-Carlson并行前缀加法器实现
module han_carlson_adder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // 第一阶段：生成p和g信号
    wire [WIDTH-1:0] p, g;
    genvar i;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: pg_gen
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // 第二阶段：前缀计算
    wire [WIDTH:0] pp, gg;
    assign pp[0] = cin;
    assign gg[0] = 1'b0;
    
    // Han-Carlson特有处理方式 - 奇数位和偶数位分别处理
    wire [WIDTH:0] p_even, p_odd, g_even, g_odd;
    
    // 初始化
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_pg
            if (i % 2 == 0) begin
                assign p_even[i/2] = p[i];
                assign g_even[i/2] = g[i];
            end else begin
                assign p_odd[i/2] = p[i];
                assign g_odd[i/2] = g[i];
            end
        end
    endgenerate
    
    // 偶数位的前缀计算
    wire [WIDTH/2:0] p_even_prefix, g_even_prefix;
    assign p_even_prefix[0] = pp[0];
    assign g_even_prefix[0] = gg[0];
    
    generate
        for (i = 1; i <= WIDTH/2; i = i + 1) begin: even_prefix
            assign p_even_prefix[i] = p_even[i-1] & p_even_prefix[i-1];
            assign g_even_prefix[i] = g_even[i-1] | (p_even[i-1] & g_even_prefix[i-1]);
        end
    endgenerate
    
    // 奇数位通过偶数位更新
    wire [WIDTH/2:0] p_odd_prefix, g_odd_prefix;
    
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin: odd_prefix
            assign p_odd_prefix[i] = p_odd[i] & p_even_prefix[i];
            assign g_odd_prefix[i] = g_odd[i] | (p_odd[i] & g_even_prefix[i]);
        end
    endgenerate
    
    // 重组结果
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: reorder
            if (i % 2 == 0) begin
                assign pp[i+1] = p_even_prefix[i/2];
                assign gg[i+1] = g_even_prefix[i/2];
            end else begin
                assign pp[i+1] = p_odd_prefix[i/2];
                assign gg[i+1] = g_odd_prefix[i/2];
            end
        end
    endgenerate
    
    // 第三阶段：计算和与进位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sum_gen
            assign sum[i] = p[i] ^ gg[i];
        end
    endgenerate
    
    assign cout = gg[WIDTH];
endmodule