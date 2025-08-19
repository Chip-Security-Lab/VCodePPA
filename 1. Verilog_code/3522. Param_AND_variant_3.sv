//SystemVerilog
module Param_Subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    // 使用二进制补码减法算法实现
    wire [WIDTH-1:0] inverted_b;
    wire [WIDTH:0] temp_sum;
    wire [WIDTH-1:0] complement_b;
    
    // 对data_b取反
    assign inverted_b = ~data_b;
    
    // 加1形成二进制补码
    assign temp_sum = inverted_b + 1'b1;
    assign complement_b = temp_sum[WIDTH-1:0];
    
    // 执行减法：data_a + (~data_b + 1)
    assign result = data_a + complement_b;
endmodule