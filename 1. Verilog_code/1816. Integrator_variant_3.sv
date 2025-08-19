//SystemVerilog
module Integrator #(parameter W=8, MAX=255) (
    input clk, rst,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    reg [W+1:0] accumulator;
    wire [W+1:0] next_accum;
    wire [W-1:0] subtrahend;
    wire [W+1:0] diff;
    
    // 使用并行前缀减法器计算
    ParallelPrefixSubtractor #(
        .WIDTH(W+2)
    ) subtractor (
        .a(accumulator),
        .b({2'b00, subtrahend}),
        .diff(diff)
    );
    
    // 确定是否需要减法操作
    assign subtrahend = (accumulator > MAX) ? (accumulator[W-1:0] - MAX) : 0;
    assign next_accum = accumulator + din - {2'b00, subtrahend};
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            accumulator <= 0;
            dout <= 0;
        end else begin
            accumulator <= next_accum;
            dout <= (accumulator > MAX) ? MAX : accumulator[W-1:0];
        end
    end
endmodule

// 并行前缀减法器实现
module ParallelPrefixSubtractor #(
    parameter WIDTH = 10
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p, g;
    wire [WIDTH-1:0] pp [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] gp [0:$clog2(WIDTH)];
    
    // 生成B的补码
    assign b_complement = ~b;
    assign carry[0] = 1'b1; // 补码加1
    
    // 生成初始传播和生成信号
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b_complement[i];
            assign g[i] = a[i] & b_complement[i];
            assign pp[0][i] = p[i];
            assign gp[0][i] = g[i];
        end
    endgenerate
    
    // 并行前缀树实现
    generate
        for (j = 0; j < $clog2(WIDTH); j = j + 1) begin: prefix_level
            for (k = 0; k < WIDTH; k = k + 1) begin: prefix_bit
                if (k >= (2**j)) begin
                    assign pp[j+1][k] = pp[j][k] & pp[j][k-(2**j)];
                    assign gp[j+1][k] = gp[j][k] | (pp[j][k] & gp[j][k-(2**j)]);
                end else begin
                    assign pp[j+1][k] = pp[j][k];
                    assign gp[j+1][k] = gp[j][k];
                end
            end
        end
    endgenerate
    
    // 计算进位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            assign carry[i+1] = gp[$clog2(WIDTH)][i] | (pp[$clog2(WIDTH)][i] & carry[0]);
        end
    endgenerate
    
    // 计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_diff
            assign diff[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule