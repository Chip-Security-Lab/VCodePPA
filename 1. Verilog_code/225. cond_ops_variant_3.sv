//SystemVerilog
// 顶层模块
module cond_ops (
    input [3:0] val,
    input sel,
    output [3:0] mux_out,
    output [3:0] invert
);
    // 连接信号
    wire [3:0] add_result;
    wire [3:0] sub_result;
    
    // 实例化加法子模块
    adder_unit adder_inst (
        .data_in(val),
        .data_out(add_result)
    );
    
    // 实例化减法子模块
    subtractor_unit subtractor_inst (
        .data_in(val),
        .data_out(sub_result)
    );
    
    // 实例化多路选择器子模块
    mux_unit mux_inst (
        .sel(sel),
        .in_a(add_result),
        .in_b(sub_result),
        .out(mux_out)
    );
    
    // 实例化反转器子模块
    inverter_unit inverter_inst (
        .data_in(val),
        .data_out(invert)
    );
endmodule

// 加法子模块
module adder_unit #(
    parameter ADD_VALUE = 4'd5
)(
    input [3:0] data_in,
    output [3:0] data_out
);
    assign data_out = data_in + ADD_VALUE;
endmodule

// 减法子模块
module subtractor_unit #(
    parameter SUB_VALUE = 4'd3
)(
    input [3:0] data_in,
    output [3:0] data_out
);
    assign data_out = data_in - SUB_VALUE;
endmodule

// 多路选择器子模块
module mux_unit (
    input sel,
    input [3:0] in_a,
    input [3:0] in_b,
    output [3:0] out
);
    assign out = sel ? in_a : in_b;
endmodule

// 反转器子模块
module inverter_unit (
    input [3:0] data_in,
    output [3:0] data_out
);
    assign data_out = ~data_in;
endmodule