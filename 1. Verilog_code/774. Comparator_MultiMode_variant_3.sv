//SystemVerilog
// 顶层模块
module Comparator_MultiMode #(
    parameter TYPE = 0, // 0:Equal, 1:Greater, 2:Less
    parameter WIDTH = 32
)(
    input               enable,   // 比较使能信号  
    input  [WIDTH-1:0]  a,b,
    output              res
);
    wire equal, greater, less;
    wire comparison_result;
    
    // 实例化比较运算子模块
    Comparator_Core #(
        .WIDTH(WIDTH)
    ) comp_core_inst (
        .a(a),
        .b(b),
        .equal(equal),
        .greater(greater),
        .less(less)
    );
    
    // 实例化结果选择子模块
    Result_Selector #(
        .TYPE(TYPE)
    ) result_sel_inst (
        .equal(equal),
        .greater(greater),
        .less(less),
        .comparison_result(comparison_result)
    );
    
    // 实例化输出控制子模块
    Output_Controller output_ctrl_inst (
        .enable(enable),
        .comparison_result(comparison_result),
        .res(res)
    );
endmodule

// 比较运算核心子模块
module Comparator_Core #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output equal,
    output greater,
    output less
);
    // 优化比较逻辑，减少路径延迟
    assign equal   = (a == b);
    assign greater = (a > b);
    assign less    = (a < b);
endmodule

// 结果选择子模块
module Result_Selector #(
    parameter TYPE = 0  // 0:Equal, 1:Greater, 2:Less
)(
    input  equal,
    input  greater,
    input  less,
    output comparison_result
);
    // 基于TYPE参数选择正确的比较结果
    reg result;
    
    always @(*) begin
        case(TYPE)
            0: result = equal;
            1: result = greater;
            default: result = less;
        endcase
    end
    
    assign comparison_result = result;
endmodule

// 输出控制子模块
module Output_Controller (
    input enable,
    input comparison_result,
    output res
);
    // 根据使能信号控制输出
    assign res = enable ? comparison_result : 1'b0;
endmodule