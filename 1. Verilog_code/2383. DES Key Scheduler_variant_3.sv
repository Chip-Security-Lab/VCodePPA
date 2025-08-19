//SystemVerilog
// 顶层模块
module des_key_scheduler #(
    parameter KEY_WIDTH = 56,
    parameter KEY_OUT = 48
) (
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [5:0] round,
    output wire [KEY_OUT-1:0] subkey
);
    // 内部连线
    wire [KEY_WIDTH-1:0] rotated_key;
    wire [19:0] borrow_sub_result;
    
    // 1. 密钥轮转子模块
    key_rotator #(
        .KEY_WIDTH(KEY_WIDTH)
    ) key_rot_inst (
        .key_in(key_in),
        .round(round),
        .rotated_key(rotated_key)
    );
    
    // 2. 条件反相减法器子模块
    conditional_inverse_subtractor #(
        .WIDTH(20)
    ) cis_inst (
        .minuend(rotated_key[19:0]),
        .subtrahend(rotated_key[39:20]),
        .result(borrow_sub_result)
    );
    
    // 3. 子密钥排列子模块
    subkey_permutation #(
        .KEY_WIDTH(KEY_WIDTH),
        .KEY_OUT(KEY_OUT)
    ) subkey_perm_inst (
        .rotated_key(rotated_key),
        .borrow_result(borrow_sub_result),
        .subkey(subkey)
    );
endmodule

// 密钥轮转子模块
module key_rotator #(
    parameter KEY_WIDTH = 56
) (
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [5:0] round,
    output wire [KEY_WIDTH-1:0] rotated_key
);
    // 基于轮数的左循环移位 (PC-1 简化版)
    assign rotated_key = (round[0]) ? {key_in[KEY_WIDTH-2:0], key_in[KEY_WIDTH-1]} :
                                      {key_in[KEY_WIDTH-3:0], key_in[KEY_WIDTH-1:KEY_WIDTH-2]};
endmodule

// 条件反相减法器子模块
module conditional_inverse_subtractor #(
    parameter WIDTH = 20
) (
    input wire [WIDTH-1:0] minuend,
    input wire [WIDTH-1:0] subtrahend,
    output wire [WIDTH-1:0] result
);
    // 条件反相减法器算法实现
    wire [WIDTH-1:0] inverted_subtrahend;
    wire [WIDTH:0] carry;
    wire perform_invert;
    
    // 判断是否需要反相
    assign perform_invert = (minuend < subtrahend);
    
    // 根据条件反相被减数
    assign inverted_subtrahend = perform_invert ? ~subtrahend : subtrahend;
    
    // 初始进位值
    assign carry[0] = perform_invert ? 1'b1 : 1'b0;
    
    // 计算过程，类似加法器实现
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_logic
            wire minuend_bit = perform_invert ? ~minuend[i] : minuend[i];
            assign result[i] = minuend_bit ^ inverted_subtrahend[i] ^ carry[i];
            assign carry[i+1] = (minuend_bit & inverted_subtrahend[i]) | 
                               (minuend_bit & carry[i]) | 
                               (inverted_subtrahend[i] & carry[i]);
        end
    endgenerate
endmodule

// 子密钥排列子模块
module subkey_permutation #(
    parameter KEY_WIDTH = 56,
    parameter KEY_OUT = 48
) (
    input wire [KEY_WIDTH-1:0] rotated_key,
    input wire [19:0] borrow_result,
    output wire [KEY_OUT-1:0] subkey
);
    // 压缩置换 (PC-2 简化版) 与借位减法器结果组合
    assign subkey = {rotated_key[45:20], borrow_result, rotated_key[55:46]};
endmodule