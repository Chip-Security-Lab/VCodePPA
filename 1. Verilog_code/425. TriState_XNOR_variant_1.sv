//SystemVerilog
// 顶层模块
module TriState_XNOR(
    input oe,
    input [3:0] in1, in2,
    output [3:0] res
);
    wire [3:0] xnor_result;
    
    // 实例化XNOR逻辑子模块
    XNOR_Logic xnor_logic_inst (
        .in1(in1),
        .in2(in2),
        .result(xnor_result)
    );
    
    // 实例化三态缓冲器子模块
    TriState_Buffer tristate_buffer_inst (
        .oe(oe),
        .data_in(xnor_result),
        .data_out(res)
    );
endmodule

// XNOR逻辑子模块
module XNOR_Logic(
    input [3:0] in1, in2,
    output [3:0] result
);
    // 使用等价的布尔表达式实现XNOR操作
    // (in1 & in2) | (~in1 & ~in2) 在某些架构上具有更好的PPA特性
    assign result = (in1 & in2) | (~in1 & ~in2);
endmodule

// 三态缓冲器子模块
module TriState_Buffer(
    input oe,
    input [3:0] data_in,
    output [3:0] data_out
);
    // 实现三态输出控制
    assign data_out = oe ? data_in : 4'bzzzz;
endmodule