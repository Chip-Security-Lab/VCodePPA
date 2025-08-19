module Comparator_GrayCode #(
    parameter WIDTH = 4,
    parameter THRESHOLD = 1      // 允许差异位数
)(
    input  [WIDTH-1:0] gray_code_a,
    input  [WIDTH-1:0] gray_code_b,
    output             is_adjacent  
);
    // 格雷码差异检测
    wire [WIDTH-1:0] xor_result = gray_code_a ^ gray_code_b;
    wire [WIDTH:0] pop_count;    // 汉明距离计算
    
    assign pop_count = xor_result[0] + xor_result[1] + 
                      xor_result[2] + xor_result[3];
    
    assign is_adjacent = (pop_count <= THRESHOLD);
endmodule