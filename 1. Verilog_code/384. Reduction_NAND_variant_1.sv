//SystemVerilog
// 顶层模块
module Reduction_NAND (
    input [7:0] vec,
    output result
);
    // 内部连线
    wire [7:0] inverted_vec;
    
    // 实例化子模块
    VectorInverter inverter_inst (
        .data_in(vec),
        .data_out(inverted_vec)
    );
    
    OrReduction or_reduction_inst (
        .data_in(inverted_vec),
        .result(result)
    );
endmodule

// 子模块：向量反转器
module VectorInverter (
    input [7:0] data_in,
    output [7:0] data_out
);
    // 对每个位进行反转操作
    // 使用generate结构提高代码可读性和PPA
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : invert_bit
            assign data_out[i] = ~data_in[i];
        end
    endgenerate
endmodule

// 子模块：OR归约运算
module OrReduction (
    input [7:0] data_in,
    output result
);
    // 通过分层实现OR归约，可以改善时序和面积
    wire [3:0] intermediate;
    
    // 第一级归约
    assign intermediate[0] = data_in[0] | data_in[1];
    assign intermediate[1] = data_in[2] | data_in[3];
    assign intermediate[2] = data_in[4] | data_in[5];
    assign intermediate[3] = data_in[6] | data_in[7];
    
    // 第二级归约
    wire [1:0] second_level;
    assign second_level[0] = intermediate[0] | intermediate[1];
    assign second_level[1] = intermediate[2] | intermediate[3];
    
    // 最终输出
    assign result = second_level[0] | second_level[1];
endmodule