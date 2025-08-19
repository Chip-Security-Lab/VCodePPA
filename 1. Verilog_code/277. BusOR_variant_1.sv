//SystemVerilog
// 顶层模块：BusOR_Top
module BusOR_Top (
    input  [15:0] bus_a,
    input  [15:0] bus_b,
    output [15:0] bus_or
);
    // 实例化16位带状进位加法器OR操作子模块
    BusOR16_BCA u_busor16_bca (
        .in_a   (bus_a),
        .in_b   (bus_b),
        .out_or (bus_or)
    );
endmodule

// 子模块：BusOR16_BCA
// 功能：对两个16位输入总线进行逐位OR操作，采用带状进位加法器结构
module BusOR16_BCA (
    input  [15:0] in_a,
    input  [15:0] in_b,
    output [15:0] out_or
);
    // 带状进位加法器参数定义
    localparam BLOCK_WIDTH = 4;
    localparam NUM_BLOCKS = 16 / BLOCK_WIDTH;

    wire [15:0] generate_sig;
    wire [15:0] propagate_sig;
    wire [NUM_BLOCKS:0] carry_chain;

    assign carry_chain[0] = 1'b0; // OR操作无进位，起始进位为0

    // 生成与传递信号
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_gp_signal
            assign generate_sig[i]  = in_a[i] | in_b[i]; // OR操作即为generate
            assign propagate_sig[i] = in_a[i] & in_b[i]; // propagate信号用于块进位链
        end
    endgenerate

    // 块进位链生成（模拟带状进位加法器结构，但OR操作进位链始终为0）
    genvar b;
    generate
        for (b = 0; b < NUM_BLOCKS; b = b + 1) begin : block_chain
            wire block_generate;
            wire block_propagate;
            assign block_generate  = |generate_sig[b*BLOCK_WIDTH +: BLOCK_WIDTH];
            assign block_propagate = &propagate_sig[b*BLOCK_WIDTH +: BLOCK_WIDTH];
            assign carry_chain[b+1] = block_generate | (block_propagate & carry_chain[b]);
        end
    endgenerate

    // OR操作输出直接取generate信号
    assign out_or = generate_sig;

endmodule