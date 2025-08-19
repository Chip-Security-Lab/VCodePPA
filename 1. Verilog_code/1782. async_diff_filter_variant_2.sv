//SystemVerilog
//=========================================================
// 顶层模块：异步差分滤波器
//=========================================================
module async_diff_filter #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] current_sample,
    input [DATA_SIZE-1:0] prev_sample,
    output [DATA_SIZE:0] diff_out  // One bit wider to handle negative
);
    // 直接在顶层模块计算结果，避免子模块实例化开销
    // 符号扩展处理
    wire [DATA_SIZE:0] extended_current = {current_sample[DATA_SIZE-1], current_sample};
    wire [DATA_SIZE:0] extended_prev = {prev_sample[DATA_SIZE-1], prev_sample};
    
    // 使用简化的减法器直接计算差值
    optimized_subtractor #(
        .WIDTH(DATA_SIZE+1)
    ) diff_calc (
        .a(extended_current),
        .b(extended_prev),
        .result(diff_out)
    );
endmodule

//=========================================================
// 优化的减法器
//=========================================================
module optimized_subtractor #(
    parameter WIDTH = 11
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    // 简化的进位传播减法器实现
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] b_neg;
    
    // 取反码，避免+1操作的额外进位链
    assign b_neg = ~b;
    assign carry[0] = 1'b1; // 初始进位设为1（用于减法）
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            assign carry[i+1] = (a[i] & b_neg[i]) | ((a[i] | b_neg[i]) & carry[i]);
        end
    endgenerate
    
    // 使用异或计算结果位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign result[i] = a[i] ^ b_neg[i] ^ carry[i];
        end
    endgenerate
endmodule