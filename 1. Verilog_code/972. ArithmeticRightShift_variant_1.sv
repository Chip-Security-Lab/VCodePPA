//SystemVerilog
// 顶层模块
module ArithmeticRightShift #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input shift_amount,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] sign_extended_data;
    wire [WIDTH-1:0] shifted_data;
    
    // 实例化符号位提取与扩展子模块
    SignExtractor #(
        .WIDTH(WIDTH)
    ) sign_ext_inst (
        .data_in(data_in),
        .sign_extended_data(sign_extended_data)
    );
    
    // 实例化移位操作子模块
    ShiftOperator #(
        .WIDTH(WIDTH)
    ) shift_op_inst (
        .data_in(sign_extended_data),
        .shift_amount(shift_amount),
        .shifted_data(shifted_data)
    );
    
    // 实例化结果输出处理子模块
    ResultProcessor #(
        .WIDTH(WIDTH)
    ) result_proc_inst (
        .shifted_data(shifted_data),
        .data_out(data_out)
    );
    
endmodule

// 符号位提取与扩展子模块
module SignExtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] sign_extended_data
);
    // 提取符号位并准备用于算术右移的数据
    assign sign_extended_data = data_in;
    
endmodule

// 移位操作子模块
module ShiftOperator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input shift_amount,
    output [WIDTH-1:0] shifted_data
);
    // 执行算术右移操作
    assign shifted_data = $signed(data_in) >>> shift_amount;
    
endmodule

// 结果输出处理子模块
module ResultProcessor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] shifted_data,
    output [WIDTH-1:0] data_out
);
    // 输出最终结果
    assign data_out = shifted_data;
    
endmodule