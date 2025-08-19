//SystemVerilog
///////////////////////////////////////////////////////////
// 文件: Hierarchical_AND.v
// 描述: 顶层模块，连接基础AND运算单元和零扩展单元
///////////////////////////////////////////////////////////
module Hierarchical_AND #(
    parameter BIT_WIDTH = 2,
    parameter OUT_WIDTH = 4
)(
    input [BIT_WIDTH-1:0] in1, in2,
    output [OUT_WIDTH-1:0] res
);
    wire [BIT_WIDTH-1:0] and_result;
    
    // 实例化位运算单元
    BitOps_Unit #(
        .BIT_WIDTH(BIT_WIDTH)
    ) bit_ops_inst (
        .in1(in1),
        .in2(in2),
        .and_result(and_result)
    );
    
    // 实例化零扩展单元
    ZeroExtend_Unit #(
        .IN_WIDTH(BIT_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) zero_extend_inst (
        .data_in(and_result),
        .data_out(res)
    );
    
endmodule

///////////////////////////////////////////////////////////
// 文件: BitOps_Unit.v
// 描述: 执行按位运算的子模块
///////////////////////////////////////////////////////////
module BitOps_Unit #(
    parameter BIT_WIDTH = 2
)(
    input [BIT_WIDTH-1:0] in1,
    input [BIT_WIDTH-1:0] in2,
    output [BIT_WIDTH-1:0] and_result
);
    genvar i;
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : and_bit
            AND_Basic and_gate (
                .a(in1[i]),
                .b(in2[i]),
                .y(and_result[i])
            );
        end
    endgenerate
endmodule

///////////////////////////////////////////////////////////
// 文件: ZeroExtend_Unit.v
// 描述: 将输入数据扩展到更宽的输出位宽，高位补零
///////////////////////////////////////////////////////////
module ZeroExtend_Unit #(
    parameter IN_WIDTH = 2,
    parameter OUT_WIDTH = 4
)(
    input [IN_WIDTH-1:0] data_in,
    output [OUT_WIDTH-1:0] data_out
);
    assign data_out[IN_WIDTH-1:0] = data_in;
    assign data_out[OUT_WIDTH-1:IN_WIDTH] = {(OUT_WIDTH-IN_WIDTH){1'b0}};
endmodule

///////////////////////////////////////////////////////////
// 文件: AND_Basic.v
// 描述: 基本AND门实现，最小功能单元
///////////////////////////////////////////////////////////
module AND_Basic(
    input a, b,
    output y
);
    assign y = a & b;
endmodule