//SystemVerilog
module bcd_comparator(
    input [3:0] bcd_digit_a,  // BCD digit (0-9)
    input [3:0] bcd_digit_b,  // BCD digit (0-9)
    output reg equal,         // A equals B
    output reg greater,       // A greater than B
    output reg less,          // A less than B
    output reg invalid_bcd    // High if either input is not a valid BCD digit
);
    // 优化的BCD验证逻辑 - 使用更高效的范围检查
    wire [1:0] a_valid_bits = {bcd_digit_a[3], bcd_digit_a[3:1] == 3'b001};
    wire [1:0] b_valid_bits = {bcd_digit_b[3], bcd_digit_b[3:1] == 3'b001};
    
    // 有效性检查 - 使用查表法代替比较
    wire valid_a = (a_valid_bits == 2'b00) || (a_valid_bits == 2'b10 && !bcd_digit_a[0]);
    wire valid_b = (b_valid_bits == 2'b00) || (b_valid_bits == 2'b10 && !bcd_digit_b[0]);
    
    // 比较结果预计算
    wire raw_equal = (bcd_digit_a == bcd_digit_b);
    wire raw_greater = (bcd_digit_a > bcd_digit_b);
    
    always @(*) begin
        // 无效检查 - 提前计算以减少关键路径
        invalid_bcd = !valid_a || !valid_b;
        
        // 使用条件运算符替代if-else结构
        equal = invalid_bcd ? 1'b0 : raw_equal;
        greater = invalid_bcd ? 1'b0 : raw_greater;
        less = invalid_bcd ? 1'b0 : !(raw_equal || raw_greater);
    end
endmodule