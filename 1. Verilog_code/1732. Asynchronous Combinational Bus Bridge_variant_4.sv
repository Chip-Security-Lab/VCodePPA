//SystemVerilog
// 补码计算子模块
module complement_calc #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] complement_out
);
    assign complement_out = ~data_in + 1;
endmodule

// 减法运算子模块
module subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a_complement,
    input [WIDTH-1:0] b_data,
    output [WIDTH-1:0] result,
    output borrow
);
    assign {borrow, result} = a_complement + b_data;
endmodule

// 控制信号处理子模块
module ctrl_signal_handler (
    input a_valid,
    input b_ready,
    output a_ready,
    output b_valid
);
    assign b_valid = a_valid;
    assign a_ready = b_ready;
endmodule

// 顶层模块
module async_bridge #(parameter WIDTH=8) (
    input [WIDTH-1:0] a_data,
    input a_valid, b_ready,
    output [WIDTH-1:0] b_data,
    output a_ready, b_valid
);
    wire [WIDTH-1:0] a_complement;
    wire [WIDTH-1:0] sub_result;
    wire borrow;

    complement_calc #(WIDTH) comp_calc (
        .data_in(a_data),
        .complement_out(a_complement)
    );

    subtractor #(WIDTH) sub_unit (
        .a_complement(a_complement),
        .b_data(b_data),
        .result(sub_result),
        .borrow(borrow)
    );

    ctrl_signal_handler ctrl_handler (
        .a_valid(a_valid),
        .b_ready(b_ready),
        .a_ready(a_ready),
        .b_valid(b_valid)
    );

    assign b_data = sub_result;

endmodule