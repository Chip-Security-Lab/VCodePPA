//SystemVerilog
//===================================================================
// 顶层模块: bitwise_mix
//===================================================================
module bitwise_mix (
    input [7:0] data_a,
    input [7:0] data_b,
    output [7:0] xor_out,
    output [7:0] nand_out
);
    // 实例化位运算控制器
    bitwise_controller #(
        .DATA_WIDTH(8)
    ) controller_inst (
        .data_a(data_a),
        .data_b(data_b),
        .xor_out(xor_out),
        .nand_out(nand_out)
    );
endmodule

//===================================================================
// 位运算控制器模块
//===================================================================
module bitwise_controller #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_a,
    input [DATA_WIDTH-1:0] data_b,
    output [DATA_WIDTH-1:0] xor_out,
    output [DATA_WIDTH-1:0] nand_out
);
    // 实例化XOR运算子模块
    xor_operation #(
        .DATA_WIDTH(DATA_WIDTH)
    ) xor_op_inst (
        .in_a(data_a),
        .in_b(data_b),
        .result(xor_out)
    );
    
    // 实例化NAND运算子模块
    nand_operation #(
        .DATA_WIDTH(DATA_WIDTH)
    ) nand_op_inst (
        .in_a(data_a),
        .in_b(data_b),
        .result(nand_out)
    );
endmodule

//===================================================================
// XOR操作子模块
//===================================================================
module xor_operation #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] in_a,
    input [DATA_WIDTH-1:0] in_b,
    output [DATA_WIDTH-1:0] result
);
    // 使用生成块以支持任意宽度的参数化设计
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : xor_gen
            assign result[i] = in_a[i] ^ in_b[i];
        end
    endgenerate
endmodule

//===================================================================
// NAND操作子模块
//===================================================================
module nand_operation #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] in_a,
    input [DATA_WIDTH-1:0] in_b,
    output [DATA_WIDTH-1:0] result
);
    // 使用生成块以支持任意宽度的参数化设计
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : nand_gen
            assign result[i] = ~(in_a[i] & in_b[i]);
        end
    endgenerate
endmodule