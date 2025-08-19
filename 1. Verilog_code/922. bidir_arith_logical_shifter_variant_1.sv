//SystemVerilog
module bidir_arith_logical_shifter (
    input  [31:0] src,
    input  [4:0]  amount,
    input         direction,  // 0=left, 1=right
    input         arith_mode, // 0=logical, 1=arithmetic
    output [31:0] result
);
    // 中间信号声明
    wire [31:0] left_shift_stage0, left_shift_stage1, left_shift_stage2, left_shift_stage3, left_shift_stage4;
    wire [31:0] right_logical_stage0, right_logical_stage1, right_logical_stage2, right_logical_stage3, right_logical_stage4;
    wire [31:0] right_arith_stage0, right_arith_stage1, right_arith_stage2, right_arith_stage3, right_arith_stage4;
    wire [31:0] right_shift_result;
    
    // 左移桶形移位器 (各级分别移动1,2,4,8,16位)
    assign left_shift_stage0 = amount[0] ? {src[30:0], 1'b0} : src;
    assign left_shift_stage1 = amount[1] ? {left_shift_stage0[29:0], 2'b0} : left_shift_stage0;
    assign left_shift_stage2 = amount[2] ? {left_shift_stage1[27:0], 4'b0} : left_shift_stage1;
    assign left_shift_stage3 = amount[3] ? {left_shift_stage2[23:0], 8'b0} : left_shift_stage2;
    assign left_shift_stage4 = amount[4] ? {left_shift_stage3[15:0], 16'b0} : left_shift_stage3;
    
    // 右逻辑移位桶形移位器
    assign right_logical_stage0 = amount[0] ? {1'b0, src[31:1]} : src;
    assign right_logical_stage1 = amount[1] ? {2'b0, right_logical_stage0[31:2]} : right_logical_stage0;
    assign right_logical_stage2 = amount[2] ? {4'b0, right_logical_stage1[31:4]} : right_logical_stage1;
    assign right_logical_stage3 = amount[3] ? {8'b0, right_logical_stage2[31:8]} : right_logical_stage2;
    assign right_logical_stage4 = amount[4] ? {16'b0, right_logical_stage3[31:16]} : right_logical_stage3;
    
    // 右算术移位桶形移位器
    wire sign_bit = src[31];
    assign right_arith_stage0 = amount[0] ? {sign_bit, src[31:1]} : src;
    assign right_arith_stage1 = amount[1] ? {{2{sign_bit}}, right_arith_stage0[31:2]} : right_arith_stage0;
    assign right_arith_stage2 = amount[2] ? {{4{sign_bit}}, right_arith_stage1[31:4]} : right_arith_stage1;
    assign right_arith_stage3 = amount[3] ? {{8{sign_bit}}, right_arith_stage2[31:8]} : right_arith_stage2;
    assign right_arith_stage4 = amount[4] ? {{16{sign_bit}}, right_arith_stage3[31:16]} : right_arith_stage3;
    
    // 右移结果选择
    assign right_shift_result = arith_mode ? right_arith_stage4 : right_logical_stage4;
    
    // 最终结果选择
    assign result = direction ? right_shift_result : left_shift_stage4;
endmodule