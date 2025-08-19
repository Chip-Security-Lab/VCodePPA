//SystemVerilog
`timescale 1ns / 1ps

module active_low_decoder(
    input [2:0] address,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] decode_n,
    output [15:0] product
);
    // 分离的always块处理默认值设置
    always @(*) begin
        decode_n = 8'hFF;  // Default all outputs to inactive (high)
    end
    
    // 分离的always块处理地址解码
    always @(*) begin
        decode_n[address] = 1'b0;  // Only selected output is active (low)
    end
    
    // 实例化Karatsuba乘法器
    karatsuba_multiplier #(
        .WIDTH(8)
    ) mult_inst (
        .a(a),
        .b(b),
        .product(product)
    );
endmodule

module karatsuba_multiplier #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] product
);
    generate
        if (WIDTH <= 4) begin : base_case
            // 基本情况：直接使用标准乘法
            assign product = a * b;
        end
        else begin : recursive_case
            // 递归情况：使用Karatsuba算法
            localparam HALF_WIDTH = WIDTH / 2;
            
            // 分割输入信号
            wire [HALF_WIDTH-1:0] a_low, b_low;
            wire [HALF_WIDTH-1:0] a_high, b_high;
            
            assign a_low = a[HALF_WIDTH-1:0];
            assign a_high = a[WIDTH-1:HALF_WIDTH];
            assign b_low = b[HALF_WIDTH-1:0];
            assign b_high = b[WIDTH-1:HALF_WIDTH];
            
            // 计算部分和
            wire [HALF_WIDTH:0] a_sum, b_sum;
            assign a_sum = a_high + a_low;
            assign b_sum = b_high + b_low;
            
            // 子乘法结果
            wire [2*HALF_WIDTH-1:0] p1; // a_high * b_high
            wire [2*HALF_WIDTH-1:0] p2; // a_low * b_low
            wire [2*HALF_WIDTH+1:0] p3_full; // (a_high + a_low) * (b_high + b_low)
            wire [2*HALF_WIDTH-1:0] p3;
            
            // 递归计算高位乘法
            karatsuba_multiplier #(
                .WIDTH(HALF_WIDTH)
            ) high_mult (
                .a(a_high),
                .b(b_high),
                .product(p1)
            );
            
            // 递归计算低位乘法
            karatsuba_multiplier #(
                .WIDTH(HALF_WIDTH)
            ) low_mult (
                .a(a_low),
                .b(b_low),
                .product(p2)
            );
            
            // 递归计算和的乘法
            karatsuba_multiplier #(
                .WIDTH(HALF_WIDTH+1)
            ) sum_mult (
                .a(a_sum),
                .b(b_sum),
                .product(p3_full)
            );
            
            // 取p3_full的低2*HALF_WIDTH位
            assign p3 = p3_full[2*HALF_WIDTH-1:0];
            
            // 计算中间项
            wire [2*HALF_WIDTH-1:0] p3_minus_p1_minus_p2;
            assign p3_minus_p1_minus_p2 = p3 - p1 - p2;
            
            // 计算最终结果的各个部分
            wire [2*WIDTH-1:0] term1, term2, term3;
            assign term1 = {p1, {HALF_WIDTH{1'b0}}, {HALF_WIDTH{1'b0}}};
            assign term2 = {{HALF_WIDTH{1'b0}}, p3_minus_p1_minus_p2, {HALF_WIDTH{1'b0}}};
            assign term3 = {{WIDTH{1'b0}}, p2};
            
            // 组合最终结果
            assign product = term1 + term2 + term3;
        end
    endgenerate
endmodule