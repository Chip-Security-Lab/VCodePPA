//SystemVerilog

//子模块：数据选择器
module DataSelector #(parameter W=4) (
    input [3:0][W-1:0] data_ch, // 输入数据通道
    input [1:0] sel,            // 选择信号
    output reg [W-1:0] data_out // 输出数据
);
    always @(*) begin
        data_out = data_ch[sel]; // 根据选择信号选择数据
    end
endmodule

//子模块：奇偶校验计算器
module ParityCalculator #(parameter W=4) (
    input [W-1:0] data_in,     // 输入数据
    output reg parity           // 输出奇偶校验位
);
    always @(*) begin
        parity = ^data_in; // 计算奇偶校验
    end
endmodule

//顶层模块：多路复用器与奇偶校验
module MuxParity #(parameter W=4) (
    input [3:0][W-1:0] data_ch, // 输入数据通道
    input [1:0] sel,            // 选择信号
    output [W-1:0] data_out,    // 输出数据
    output parity               // 输出奇偶校验位
);
    wire [W-1:0] selected_data; // 选择的数据

    // 实例化数据选择器
    DataSelector #(W) data_selector (
        .data_ch(data_ch),
        .sel(sel),
        .data_out(selected_data)
    );

    // 实例化奇偶校验计算器
    ParityCalculator #(W) parity_calculator (
        .data_in(selected_data),
        .parity(parity)
    );

    assign data_out = selected_data; // 将选择的数据输出
endmodule