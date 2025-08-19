//SystemVerilog
// 顶层模块 - 8位借位减法器
module xor2_12 #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    // 实例化位宽可配置的借位减法器核心模块
    borrow_subtractor_core #(
        .WIDTH(WIDTH)
    ) borrow_subtractor_inst (
        .a_in(A),
        .b_in(B),
        .diff_out(Y)
    );
endmodule

// 借位减法器核心计算模块
module borrow_subtractor_core #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a_in,
    input  wire [WIDTH-1:0] b_in,
    output wire [WIDTH-1:0] diff_out
);
    // 借位信号连接
    wire [WIDTH:0] borrow;
    assign borrow[0] = 1'b0; // 初始无借位
    
    // 使用生成块动态创建全减器单元
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : full_subtractor_gen
            full_subtractor_cell fs_inst (
                .a(a_in[i]),
                .b(b_in[i]),
                .b_in(borrow[i]),
                .diff(diff_out[i]),
                .b_out(borrow[i+1])
            );
        end
    endgenerate
endmodule

// 全减器基本单元
module full_subtractor_cell (
    input  wire a,      // 被减数位
    input  wire b,      // 减数位
    input  wire b_in,   // 来自低位的借位输入
    output wire diff,   // 差值输出
    output wire b_out   // 向高位的借位输出
);
    // 计算差值
    assign diff = a ^ b ^ b_in;
    
    // 计算借位 - 当a<b或者a=b但有借位输入时产生借位
    assign b_out = (~a & b) | ((~(a ^ b)) & b_in);
endmodule