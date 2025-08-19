//SystemVerilog
module Comparator_FaultTolerant #(
    parameter WIDTH = 8,
    parameter PARITY_TYPE = 0    // 0:偶校验 1:奇校验
)(
    input  [WIDTH:0]   data_a,   // [WIDTH]为校验位
    input  [WIDTH:0]   data_b,
    output             safe_equal
);
    // ===== 第一级流水线 - 校验计算 =====
    // 计算数据A的实际校验位
    wire actual_parity_a = ^data_a[WIDTH-1:0];
    // 计算数据B的实际校验位
    wire actual_parity_b = ^data_b[WIDTH-1:0];
    
    // 预期的校验位
    wire expected_parity_a = PARITY_TYPE ? ~data_a[WIDTH] : data_a[WIDTH];
    wire expected_parity_b = PARITY_TYPE ? ~data_b[WIDTH] : data_b[WIDTH];
    
    // 校验结果
    wire parity_ok_a = (actual_parity_a == expected_parity_a);
    wire parity_ok_b = (actual_parity_b == expected_parity_b);

    // 组合校验结果
    wire parity_check_passed = parity_ok_a & parity_ok_b;
    
    // ===== 第二级流水线 - 数据比较 =====
    // 提取数据部分
    wire [WIDTH-1:0] data_value_a = data_a[WIDTH-1:0];
    wire [WIDTH-1:0] data_value_b = data_b[WIDTH-1:0];
    
    // 三种比较方式并行执行，增加容错性
    
    // 方法1: 直接比较
    wire direct_equal = (data_value_a == data_value_b);
    
    // 方法2: 二进制补码减法比较
    wire [WIDTH-1:0] data_b_complement = ~data_value_b + 1'b1;
    wire [WIDTH-1:0] sub_result = data_value_a + data_b_complement;
    wire subtraction_equal = (sub_result == {WIDTH{1'b0}});
    
    // 方法3: 位级异或比较
    wire [WIDTH-1:0] xor_result = data_value_a ^ data_value_b;
    wire xor_equal = (xor_result == {WIDTH{1'b0}});
    
    // ===== 第三级流水线 - 结果整合 =====
    // 比较结果表决
    wire comparison_passed = (direct_equal & subtraction_equal) | 
                             (direct_equal & xor_equal) | 
                             (subtraction_equal & xor_equal);
    
    // 最终安全比较结果
    assign safe_equal = parity_check_passed & comparison_passed;
    
endmodule