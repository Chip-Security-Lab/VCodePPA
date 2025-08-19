//SystemVerilog
//Verilog-2005
///////////////////////////////////////////////
// 顶层模块 - 2位按位与操作，带有4位输出接口
///////////////////////////////////////////////
module Hierarchical_AND (
    input  wire [1:0] in1, in2,
    output wire [3:0] res
);
    // 内部连线
    wire [1:0] and_result;
    
    // 实例化2位并行按位与子模块
    Parallel_AND_2bit parallel_and_inst (
        .a          (in1),
        .b          (in2),
        .and_result (and_result)
    );
    
    // 实例化结果格式化模块
    Result_Formatter formatter_inst (
        .and_result_in  (and_result),
        .formatted_out  (res)
    );

endmodule

///////////////////////////////////////////////
// 子模块：2位并行按位与运算
///////////////////////////////////////////////
module Parallel_AND_2bit (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [1:0] and_result
);
    // 实例化两个基本与门单元
    AND_Cell and_cell_0 (
        .a_in  (a[0]),
        .b_in  (b[0]),
        .y_out (and_result[0])
    );
    
    AND_Cell and_cell_1 (
        .a_in  (a[1]),
        .b_in  (b[1]),
        .y_out (and_result[1])
    );
    
endmodule

///////////////////////////////////////////////
// 子模块：基本与门单元，经过参数化优化
///////////////////////////////////////////////
module AND_Cell (
    input  wire a_in,
    input  wire b_in,
    output wire y_out
);
    // 高效的与门实现
    assign y_out = a_in & b_in;
endmodule

///////////////////////////////////////////////
// 子模块：结果格式化 - 将2位结果转换为4位输出
///////////////////////////////////////////////
module Result_Formatter (
    input  wire [1:0] and_result_in,
    output wire [3:0] formatted_out
);
    // 格式化输出为4位结果，高位清零
    assign formatted_out = {2'b00, and_result_in};
endmodule