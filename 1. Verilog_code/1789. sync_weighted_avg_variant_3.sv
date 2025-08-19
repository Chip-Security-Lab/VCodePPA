//SystemVerilog
module sync_weighted_avg #(
    parameter DW = 12,
    parameter WEIGHTS = 3
)(
    input clk, rstn,
    input [DW-1:0] sample_in,
    input [7:0] weights [WEIGHTS-1:0],
    output reg [DW-1:0] filtered_out
);
    reg [DW-1:0] samples [WEIGHTS-1:0];
    reg [DW+8-1:0] weighted_sum;
    reg [7:0] weight_sum;
    integer i;
    
    // 使用先行进位加法器计算权重和
    wire [7:0] weight_sum_cla;
    cla_adder_8bit weight_adder(
        .a(weights[0]),
        .b(weights[1]),
        .cin(1'b0),
        .sum(weight_sum_cla),
        .cout()
    );
    
    // 用于计算weighted_sum的中间变量
    wire [DW+8-1:0] weighted_products [WEIGHTS-1:0];
    wire [DW+8-1:0] weighted_sum_cla;
    
    // 计算每个采样值与权重的乘积
    assign weighted_products[0] = samples[0] * weights[0];
    assign weighted_products[1] = samples[1] * weights[1];
    assign weighted_products[2] = samples[2] * weights[2];
    
    // 使用先行进位加法器计算乘积和
    cla_adder_wide #(
        .WIDTH(DW+8)
    ) product_adder (
        .a(weighted_products[0]),
        .b(weighted_products[1]),
        .cin(1'b0),
        .sum(weighted_sum_cla),
        .cout()
    );
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < WEIGHTS; i = i + 1)
                samples[i] <= 0;
            filtered_out <= 0;
            weighted_sum <= 0;
            weight_sum <= 0;
        end else begin
            // Shift samples through delay line
            for (i = WEIGHTS-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= sample_in;
            
            // 使用先行进位加法器的结果
            weight_sum <= weight_sum_cla + weights[2];
            weighted_sum <= weighted_sum_cla + weighted_products[2];
            
            // Normalize by sum of weights
            filtered_out <= weighted_sum / weight_sum;
        end
    end
endmodule

// 8位先行进位加法器模块
module cla_adder_8bit(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] g; // 生成信号
    wire [7:0] p; // 传播信号
    wire [8:0] c; // 进位信号
    
    // 计算生成和传播信号
    assign g = a & b;
    assign p = a ^ b;
    
    // 进位计算
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    
    // 计算和
    assign sum = p ^ c[7:0];
    assign cout = c[8];
endmodule

// 宽位先行进位加法器，可参数化位宽
module cla_adder_wide #(
    parameter WIDTH = 20
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    wire [WIDTH-1:0] g; // 生成信号
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH:0] c;   // 进位信号
    
    // 计算生成和传播信号
    assign g = a & b;
    assign p = a ^ b;
    
    // 进位计算
    assign c[0] = cin;
    
    // 分级计算进位
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // 计算和
    assign sum = p ^ c[WIDTH-1:0];
    assign cout = c[WIDTH];
endmodule