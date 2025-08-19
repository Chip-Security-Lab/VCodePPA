//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module Compare_XNOR #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] a, b,
    output eq_flag
);
    wire [DATA_WIDTH-1:0] bit_eq;
    wire [DATA_WIDTH/2-1:0] stage1_eq;
    
    // 实例化低4位比较器子模块
    LowerBitsComparator #(
        .WIDTH(DATA_WIDTH/2)
    ) lower_bits_comp (
        .a_in(a[DATA_WIDTH/2-1:0]),
        .b_in(b[DATA_WIDTH/2-1:0]),
        .eq_out(bit_eq[DATA_WIDTH/2-1:0])
    );
    
    // 实例化高4位比较器子模块
    UpperBitsComparator #(
        .WIDTH(DATA_WIDTH/2)
    ) upper_bits_comp (
        .a_in(a[DATA_WIDTH-1:DATA_WIDTH/2]),
        .b_in(b[DATA_WIDTH-1:DATA_WIDTH/2]),
        .eq_out(bit_eq[DATA_WIDTH-1:DATA_WIDTH/2])
    );
    
    // 实例化第一级结果压缩子模块
    EqualityCompressor #(
        .IN_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(DATA_WIDTH/2)
    ) first_stage_comp (
        .eq_in(bit_eq),
        .eq_out(stage1_eq)
    );
    
    // 实例化最终聚合子模块
    FinalAggregator #(
        .WIDTH(DATA_WIDTH/2)
    ) final_aggregator (
        .partial_eq(stage1_eq),
        .final_eq(eq_flag)
    );
    
endmodule

// 低位比较器子模块
module LowerBitsComparator #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] a_in, b_in,
    output [WIDTH-1:0] eq_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_lower_bit_compare
            // 使用XNOR实现位比较
            BitEqualityChecker bit_check_inst (
                .a_bit(a_in[i]),
                .b_bit(b_in[i]),
                .eq_bit(eq_out[i])
            );
        end
    endgenerate
endmodule

// 高位比较器子模块
module UpperBitsComparator #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] a_in, b_in,
    output [WIDTH-1:0] eq_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_upper_bit_compare
            // 使用XNOR实现位比较
            BitEqualityChecker bit_check_inst (
                .a_bit(a_in[i]),
                .b_bit(b_in[i]),
                .eq_bit(eq_out[i])
            );
        end
    endgenerate
endmodule

// 单比特相等检查器模块
module BitEqualityChecker (
    input a_bit, b_bit,
    output eq_bit
);
    assign eq_bit = ~(a_bit ^ b_bit); // XNOR实现
endmodule

// 相等结果压缩模块
module EqualityCompressor #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 4
)(
    input [IN_WIDTH-1:0] eq_in,
    output [OUT_WIDTH-1:0] eq_out
);
    genvar i;
    generate
        for (i = 0; i < OUT_WIDTH; i = i + 1) begin : gen_compress
            // 两两压缩相邻位
            assign eq_out[i] = eq_in[i*2] & eq_in[i*2+1];
        end
    endgenerate
endmodule

// 最终聚合模块
module FinalAggregator #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] partial_eq,
    output final_eq
);
    // 使用树形结构进行最终与运算
    wire [WIDTH/2-1:0] stage_eq;
    
    genvar i;
    generate
        if (WIDTH > 1) begin
            // 首先压缩为一半的宽度
            for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_compress
                assign stage_eq[i] = partial_eq[i*2] & partial_eq[i*2+1];
            end
            
            // 最终压缩为单比特结果
            assign final_eq = &stage_eq;
        end
        else begin
            // 如果只有一位，则直接输出
            assign final_eq = partial_eq[0];
        end
    endgenerate
endmodule