module Comparator_DynamicWidth (
    input         [15:0]  data_x,
    input         [15:0]  data_y,
    input         [3:0]   valid_bits, // 有效位配置（1-16）
    output reg            unequal
);
    // 动态掩码生成
    wire [15:0] mask = (16'hFFFF << valid_bits);
    always @(*) begin
        unequal = ((data_x & ~mask) != (data_y & ~mask));
    end
endmodule