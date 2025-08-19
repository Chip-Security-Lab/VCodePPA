//SystemVerilog
module Comparator_Window #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_in,
    input  [WIDTH-1:0] low_th,
    input  [WIDTH-1:0] high_th,
    output             in_range
);
    // 使用优化的比较逻辑
    wire [WIDTH:0] diff_low, diff_high;
    wire [WIDTH-1:0] borrow_low, borrow_high;
    
    // 计算与低阈值的差值
    assign diff_low = {1'b0, data_in} - {1'b0, low_th};
    assign borrow_low = diff_low[WIDTH] ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
    
    // 计算与高阈值的差值
    assign diff_high = {1'b0, high_th} - {1'b0, data_in};
    assign borrow_high = diff_high[WIDTH] ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
    
    // 判断是否在范围内
    assign in_range = ~borrow_low[0] & ~borrow_high[0];
endmodule