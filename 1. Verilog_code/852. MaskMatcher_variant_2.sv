//SystemVerilog
module MaskMatcher #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern, mask,
    output match
);
    // 内部连线
    wire [WIDTH-1:0] masked_data;
    wire [WIDTH-1:0] masked_pattern;
    
    // 实例化子模块
    DataMasker #(
        .WIDTH(WIDTH)
    ) data_masker_inst (
        .data(data),
        .mask(mask),
        .masked_data(masked_data)
    );
    
    DataMasker #(
        .WIDTH(WIDTH)
    ) pattern_masker_inst (
        .data(pattern),
        .mask(mask),
        .masked_data(masked_pattern)
    );
    
    Comparator #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .in1(masked_data),
        .in2(masked_pattern),
        .equal(match)
    );
endmodule

module DataMasker #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] mask,
    output [WIDTH-1:0] masked_data
);
    // 对输入数据应用掩码
    assign masked_data = data & mask;
endmodule

module Comparator #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] in1,
    input [WIDTH-1:0] in2,
    output equal
);
    // 使用条件求和减法算法实现比较
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] not_in2;
    
    // 反转第二个输入
    assign not_in2 = ~in2;
    
    // 设置初始进位为1（用于补码操作）
    assign carry[0] = 1'b1;
    
    // 条件求和减法器实现
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sub
            assign diff[i] = in1[i] ^ not_in2[i] ^ carry[i];
            assign carry[i+1] = (in1[i] & not_in2[i]) | (in1[i] & carry[i]) | (not_in2[i] & carry[i]);
        end
    endgenerate
    
    // 如果所有位为0，则输入相等
    assign equal = (diff == {WIDTH{1'b0}});
endmodule