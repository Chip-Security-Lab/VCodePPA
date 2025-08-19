//SystemVerilog
//============================================================================
// XOR递归处理模块 - 顶层设计
//============================================================================
module xor_recursive #(
    parameter DATA_WIDTH = 8
)(
    input  logic [DATA_WIDTH-1:0] a, 
    input  logic [DATA_WIDTH-1:0] b, 
    output logic [DATA_WIDTH-1:0] y
);
    // 内部连接信号
    logic [DATA_WIDTH-1:0] xor_base_result;
    logic [DATA_WIDTH-2:0] cascade_result;
    
    // 实例化位级XOR计算单元
    bit_xor_unit #(
        .WIDTH(DATA_WIDTH)
    ) bit_xor_inst (
        .data_a     (a),
        .data_b     (b),
        .xor_result (xor_base_result)
    );
    
    // 实例化级联XOR处理单元
    cascade_processor #(
        .WIDTH(DATA_WIDTH)
    ) cascade_proc_inst (
        .xor_in    (xor_base_result),
        .cascade_out(cascade_result)
    );
    
    // 实例化结果合成单元
    result_combiner #(
        .WIDTH(DATA_WIDTH)
    ) result_combiner_inst (
        .xor_base   (xor_base_result),
        .cascade_in (cascade_result),
        .final_result(y)
    );
    
endmodule

//============================================================================
// 位级XOR计算模块 - 支持参数化宽度
//============================================================================
module bit_xor_unit #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] data_a,
    input  logic [WIDTH-1:0] data_b,
    output logic [WIDTH-1:0] xor_result
);
    // 简洁的向量级XOR操作，提高综合效率
    assign xor_result = data_a ^ data_b;
endmodule

//============================================================================
// 级联XOR处理模块 - 支持参数化宽度
//============================================================================
module cascade_processor #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] xor_in,
    output logic [WIDTH-2:0] cascade_out
);
    // 第一个级联值直接连接
    assign cascade_out[0] = xor_in[0];
    
    // 生成级联XOR链
    genvar i;
    generate
        for (i = 1; i < WIDTH-1; i = i + 1) begin : cascade_gen
            assign cascade_out[i] = cascade_out[i-1] ^ xor_in[i];
        end
    endgenerate
endmodule

//============================================================================
// 结果合成模块 - 支持参数化宽度
//============================================================================
module result_combiner #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] xor_base,
    input  logic [WIDTH-2:0] cascade_in,
    output logic [WIDTH-1:0] final_result
);
    // 第一位直接连接
    assign final_result[0] = xor_base[0];
    
    // 合成其余位
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : result_gen
            assign final_result[i] = xor_base[i] ^ cascade_in[i-1];
        end
    endgenerate
endmodule