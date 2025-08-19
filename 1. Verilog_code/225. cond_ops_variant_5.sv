//SystemVerilog
// 顶层模块
module cond_ops (
    input [3:0] val,
    input sel,
    output [3:0] mux_out,
    output [3:0] invert
);
    // 内部信号连接
    wire [3:0] val_plus;
    wire [3:0] val_minus;
    
    // 实例化加法子模块
    adder_unit add_op (
        .data_in(val),
        .data_out(val_plus)
    );
    
    // 实例化减法子模块
    subtractor_unit sub_op (
        .data_in(val),
        .data_out(val_minus)
    );
    
    // 实例化多路选择器子模块
    mux_unit mux_op (
        .in_a(val_plus),
        .in_b(val_minus),
        .select(sel),
        .out(mux_out)
    );
    
    // 实例化取反子模块
    inverter_unit inv_op (
        .data_in(val),
        .data_out(invert)
    );
endmodule

// 加法子模块
module adder_unit (
    input [3:0] data_in,
    output [3:0] data_out
);
    // 参数化加法常量，提高可复用性
    parameter ADD_CONST = 4'd5;
    
    assign data_out = data_in + ADD_CONST;
endmodule

// 减法子模块
module subtractor_unit (
    input [3:0] data_in,
    output [3:0] data_out
);
    // 参数化减法常量，提高可复用性
    parameter SUB_CONST = 4'd3;
    
    assign data_out = data_in - SUB_CONST;
endmodule

// 多路选择器子模块
module mux_unit (
    input [3:0] in_a,
    input [3:0] in_b,
    input select,
    output [3:0] out
);
    // 根据选择信号选择输入
    assign out = select ? in_a : in_b;
endmodule

// 取反子模块
module inverter_unit (
    input [3:0] data_in,
    output [3:0] data_out
);
    // 对输入数据进行按位取反
    assign data_out = ~data_in;
endmodule