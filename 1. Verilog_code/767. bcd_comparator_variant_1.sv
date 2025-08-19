//SystemVerilog
module bcd_comparator(
    input [3:0] bcd_digit_a,
    input [3:0] bcd_digit_b,
    output reg equal,
    output reg greater,
    output reg less,
    output reg invalid_bcd
);
    // 优化BCD有效性检查，使用一步比较
    wire valid_a = ~|{bcd_digit_a[3:1], bcd_digit_a[0] & bcd_digit_a[3]};  // a <= 9 简化
    wire valid_b = ~|{bcd_digit_b[3:1], bcd_digit_b[0] & bcd_digit_b[3]};  // b <= 9 简化
    wire both_valid = valid_a & valid_b;
    
    // 直接计算比较结果，无需中间结果
    wire a_eq_b = (bcd_digit_a == bcd_digit_b);
    wire a_gt_b = (bcd_digit_a > bcd_digit_b);
    wire a_lt_b = ~a_eq_b & ~a_gt_b;  // 使用德摩根定律简化
    
    // 组合逻辑简化，减少层级
    always @(*) begin
        invalid_bcd = ~both_valid;
        equal = both_valid & a_eq_b;
        greater = both_valid & a_gt_b;
        less = both_valid & a_lt_b;
    end
endmodule