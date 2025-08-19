//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块 - 8位比较器系统
//-----------------------------------------------------------------------------
module Compare_XNOR_System(
    input  wire [7:0] a, b,
    output wire eq_flag
);
    // 内部连线
    wire [1:0] half_eq_flags;
    
    // 实例化两个4位比较器模块
    Compare_Unit #(
        .WIDTH(4)
    ) lower_half_comparator (
        .data_a(a[3:0]),
        .data_b(b[3:0]),
        .is_equal(half_eq_flags[0])
    );
    
    Compare_Unit #(
        .WIDTH(4)
    ) upper_half_comparator (
        .data_a(a[7:4]),
        .data_b(b[7:4]),
        .is_equal(half_eq_flags[1])
    );
    
    // 实例化标志合并模块
    Flag_Combiner flags_combiner (
        .flags(half_eq_flags),
        .result(eq_flag)
    );
    
endmodule

//-----------------------------------------------------------------------------
// 子模块 - 参数化比较单元
//-----------------------------------------------------------------------------
module Compare_Unit #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] data_a, data_b,
    output wire is_equal
);
    // 内部连线
    wire [WIDTH-1:0] bit_comparisons;
    
    // 生成比特级比较器
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_compare_gen
            Bit_Compare_Element bit_comparator (
                .bit_a(data_a[i]),
                .bit_b(data_b[i]),
                .equal(bit_comparisons[i])
            );
        end
    endgenerate
    
    // 合并比特比较结果
    Bit_Result_Reducer #(
        .WIDTH(WIDTH)
    ) reducer (
        .bit_results(bit_comparisons),
        .combined_result(is_equal)
    );
    
endmodule

//-----------------------------------------------------------------------------
// 子模块 - 单比特比较元件
//-----------------------------------------------------------------------------
module Bit_Compare_Element(
    input  wire bit_a, bit_b,
    output wire equal
);
    // 使用XNOR操作实现比较（相同为1，不同为0）
    assign equal = ~(bit_a ^ bit_b);
    
endmodule

//-----------------------------------------------------------------------------
// 子模块 - 比特结果归约器
//-----------------------------------------------------------------------------
module Bit_Result_Reducer #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] bit_results,
    output wire combined_result
);
    // 所有比特比较结果必须都为1，总结果才为1
    assign combined_result = &bit_results;
    
endmodule

//-----------------------------------------------------------------------------
// 子模块 - 标志组合器
//-----------------------------------------------------------------------------
module Flag_Combiner(
    input  wire [1:0] flags,
    output wire result
);
    // 所有输入标志必须同时为1，结果才为1
    assign result = &flags;
    
endmodule