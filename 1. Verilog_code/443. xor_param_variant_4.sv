//SystemVerilog
//==================================
//==================================

//----------------------------------
// 顶层模块 - 参数化异或操作
//----------------------------------
module xor_param #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);

    // 使用Brent-Kung加法器实现异或功能
    // 异或功能等价于模2加法
    brent_kung_xor #(
        .WIDTH(WIDTH)
    ) bk_xor_inst (
        .a(a),
        .b(b),
        .y(y)
    );

endmodule

//----------------------------------
// Brent-Kung XOR模块 - 使用Brent-Kung算法实现异或
//----------------------------------
module brent_kung_xor #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    // 在Brent-Kung加法器中，我们关心的是进位生成和传播
    // 对于异或操作，我们可以直接使用传播信号
    
    wire [WIDTH-1:0] p; // 传播信号 (Propagate)
    
    // 生成传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_propagate
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // 异或结果直接等于传播信号
    assign y = p;

endmodule

//----------------------------------
// 基本单元模块 - 单比特异或操作
//----------------------------------
module xor_bit_cell (
    input  wire a_bit,
    input  wire b_bit,
    output wire y_bit
);

    // 实现单比特异或逻辑
    assign y_bit = a_bit ^ b_bit;

endmodule