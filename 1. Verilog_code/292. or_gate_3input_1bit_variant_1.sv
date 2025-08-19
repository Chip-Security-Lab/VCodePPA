//SystemVerilog
// 顶层模块 - 参数化3输入或门
module or_gate_3input_1bit #(
    parameter IN_DELAY = 0,
    parameter OUT_DELAY = 0
)(
    input wire a,
    input wire b,
    input wire c,
    output wire y
);
    // 使用更高效的直接实现替代级联实现
    // 这提升了性能、面积和功耗指标
    or_gate_3input_direct #(
        .DELAY(OUT_DELAY)
    ) or3_direct_inst (
        .in1(a),
        .in2(b),
        .in3(c),
        .out(y)
    );
endmodule

// 3输入或门直接实现子模块 - 提高性能和减少面积
module or_gate_3input_direct #(
    parameter DELAY = 0
)(
    input wire in1,
    input wire in2,
    input wire in3,
    output wire out
);
    // 直接实现3输入或操作，减少级联延迟
    assign #(DELAY) out = in1 | in2 | in3;
endmodule

// 保留原来的2输入或门子模块以保持向后兼容性
module or_gate_2input #(
    parameter DELAY = 0
)(
    input wire in1,
    input wire in2,
    output wire out
);
    // 添加可配置延迟以支持时序调优
    assign #(DELAY) out = in1 | in2;
endmodule