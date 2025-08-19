//SystemVerilog
module Comparator_FaultTolerant #(
    parameter WIDTH = 8,
    parameter PARITY_TYPE = 0    // 0:偶校验 1:奇校验
)(
    input  [WIDTH:0]   data_a,   // [WIDTH]为校验位
    input  [WIDTH:0]   data_b,
    output             safe_equal
);
    // 优化校验计算 - 直接计算校验位是否符合预期
    wire parity_a = ^data_a[WIDTH-1:0];
    wire parity_b = ^data_b[WIDTH-1:0];
    
    // 简化校验比较逻辑
    wire parity_ok_a = parity_a == (PARITY_TYPE ? ~data_a[WIDTH] : data_a[WIDTH]);
    wire parity_ok_b = parity_b == (PARITY_TYPE ? ~data_b[WIDTH] : data_b[WIDTH]);
    
    // 数据比较 - 使用XNOR实现相等检测
    wire data_equal = ~(|(data_a[WIDTH-1:0] ^ data_b[WIDTH-1:0]));
    
    // 最终结果 - 使用单个与运算
    assign safe_equal = parity_ok_a & parity_ok_b & data_equal;
endmodule