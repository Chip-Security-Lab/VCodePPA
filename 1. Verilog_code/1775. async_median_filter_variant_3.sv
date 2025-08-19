//SystemVerilog
module async_median_filter #(
    parameter W = 16
)(
    input [W-1:0] a, b, c,
    output [W-1:0] med_out
);
    wire [W-1:0] min_ab, max_ab, med_result;
    wire [W:0] diff_ab, diff_c_min, diff_max_c;
    wire sign_ab, sign_c_min, sign_max_c;
    
    // 使用带符号扩展的减法计算差值以改善时序
    assign diff_ab = {1'b0, a} + {1'b0, ~b} + {{W{1'b0}}, 1'b1};
    assign sign_ab = diff_ab[W];
    
    // 使用显式的多路复用器结构替代三元运算符
    assign min_ab = sign_ab ? a : b;
    assign max_ab = sign_ab ? b : a;
    
    // 优化比较逻辑，避免不必要的计算延迟
    assign diff_c_min = {1'b0, c} + {1'b0, ~min_ab} + {{W{1'b0}}, 1'b1};
    assign sign_c_min = diff_c_min[W];
    
    assign diff_max_c = {1'b0, max_ab} + {1'b0, ~c} + {{W{1'b0}}, 1'b1};
    assign sign_max_c = diff_max_c[W];
    
    // 使用显式的多路复用器结构替换嵌套的三元运算符
    // 实现2:1多路复用器选择c和max_ab
    wire [W-1:0] mux_high;
    assign mux_high = sign_max_c ? c : max_ab;
    
    // 实现2:1多路复用器选择min_ab和mux_high
    assign med_result = sign_c_min ? min_ab : mux_high;
    
    // 输出结果
    assign med_out = med_result;
endmodule