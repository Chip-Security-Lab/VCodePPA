//SystemVerilog
module Comparator_MultiMode #(
    parameter TYPE = 0, // 0:Equal, 1:Greater, 2:Less
    parameter WIDTH = 32
)(
    input               enable,   // 比较使能信号  
    input  [WIDTH-1:0]  a, b,
    output              res
);
    // 内部信号定义
    wire compare_result;
    wire compare_enable = enable;
    
    // 比较器核心子模块实例化
    ComparatorCore #(
        .TYPE(TYPE),
        .WIDTH(WIDTH)
    ) comparator_core_inst (
        .a(a),
        .b(b),
        .compare_result(compare_result)
    );
    
    // 输出控制子模块实例化
    OutputController output_controller_inst (
        .enable(compare_enable),
        .compare_result(compare_result),
        .res(res)
    );
endmodule

// 比较器核心子模块 - 负责不同类型的比较逻辑
module ComparatorCore #(
    parameter TYPE = 0, // 0:Equal, 1:Greater, 2:Less
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] a, b,
    output compare_result
);
    // 比较操作结果
    wire equal   = (a == b);
    wire greater = (a > b);
    wire less    = (a < b);
    
    // 根据参数选择比较结果
    reg result_mux;
    
    always @(*) begin
        case(TYPE)
            0: result_mux = equal;
            1: result_mux = greater;
            default: result_mux = less;
        endcase
    end
    
    assign compare_result = result_mux;
endmodule

// 输出控制子模块 - 处理使能控制和最终输出
module OutputController (
    input enable,
    input compare_result,
    output res
);
    // 根据使能信号控制输出
    assign res = enable ? compare_result : 1'b0;
endmodule