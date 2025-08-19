//SystemVerilog
module Comparator_Window #(parameter WIDTH = 10) (
    input  [WIDTH-1:0] data_in,
    input  [WIDTH-1:0] low_th,
    input  [WIDTH-1:0] high_th,
    output             in_range
);
    // 使用补码加法替代减法运算
    wire [WIDTH:0] lower_diff = {1'b0, data_in} + {1'b0, ~low_th} + 1'b1;
    wire [WIDTH:0] upper_diff = {1'b0, high_th} + {1'b0, ~data_in} + 1'b1;
    
    // 使用符号位检查范围，无需乘法或复杂比较器链
    assign in_range = ~(lower_diff[WIDTH] | upper_diff[WIDTH]);
endmodule