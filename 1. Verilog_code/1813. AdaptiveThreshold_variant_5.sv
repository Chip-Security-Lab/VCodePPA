//SystemVerilog
// 顶层模块
module AdaptiveThreshold #(
    parameter W = 8
)(
    input clk,
    input [W-1:0] signal,
    output threshold
);
    wire [W+3:0] filtered_sum;
    wire [W-1:0] threshold_value;

    // 信号累加滤波子模块
    SignalAccumulator #(
        .WIDTH(W)
    ) accumulator_inst (
        .clk(clk),
        .signal_in(signal),
        .filtered_sum(filtered_sum)
    );

    // 阈值计算子模块
    ThresholdGenerator #(
        .WIDTH(W)
    ) threshold_gen_inst (
        .clk(clk),
        .sum_in(filtered_sum),
        .threshold_out(threshold)
    );

endmodule

// 信号累加滤波子模块
module SignalAccumulator #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output reg [WIDTH+3:0] filtered_sum
);
    wire [WIDTH+3:0] next_sum;
    wire [WIDTH+3:0] subtracted_value;
    
    // 使用曼彻斯特进位链加法器计算
    ManchesterAdder #(
        .WIDTH(WIDTH+4)
    ) adder_inst (
        .a(filtered_sum),
        .b(signal_in),
        .cin(1'b0),
        .sum(next_sum),
        .cout()
    );
    
    // 生成要减去的值
    ManchesterAdder #(
        .WIDTH(WIDTH+4)
    ) subtractor_inst (
        .a(next_sum),
        .b(~filtered_sum[WIDTH+3:WIDTH]),
        .cin(1'b1),
        .sum(subtracted_value),
        .cout()
    );
    
    // 更新累加值
    always @(posedge clk) begin
        filtered_sum <= subtracted_value;
    end
endmodule

// 阈值计算子模块
module ThresholdGenerator #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH+3:0] sum_in,
    output reg threshold_out
);
    // 右移2位（除以4）计算阈值
    always @(posedge clk) begin
        threshold_out <= sum_in[WIDTH+3:WIDTH] >> 2;
    end
endmodule

// 曼彻斯特进位链加法器实现
module ManchesterAdder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // 生成(G)和传播(P)信号
    wire [WIDTH-1:0] g, p;
    // 进位信号
    wire [WIDTH:0] c;
    
    // 初始进位输入
    assign c[0] = cin;
    
    // 计算G(生成)和P(传播)信号
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin: gen_gp
            assign g[i] = a[i] & b[i];         // 生成信号
            assign p[i] = a[i] | b[i];         // 传播信号
        end
    endgenerate
    
    // 曼彻斯特进位链计算
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            // 曼彻斯特进位链: c[i+1] = g[i] | (p[i] & c[i])
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // 计算最终和
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = a[i] ^ b[i] ^ c[i];
        end
    endgenerate
    
    // 输出进位
    assign cout = c[WIDTH];
endmodule