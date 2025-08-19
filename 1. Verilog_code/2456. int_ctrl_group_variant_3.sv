//SystemVerilog
// 顶层模块
module int_ctrl_group #(
    parameter GROUPS = 2,
    parameter WIDTH = 4
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [GROUPS*WIDTH-1:0] int_in,
    input  wire [GROUPS-1:0]      group_en,
    output wire [GROUPS-1:0]      group_int
);

    // 实例化中断处理系统
    int_processing_system #(
        .GROUPS(GROUPS),
        .WIDTH(WIDTH)
    ) int_system (
        .clk(clk),
        .rst(rst),
        .int_signals(int_in),
        .group_enable(group_en),
        .group_interrupt(group_int)
    );

endmodule

// 中断处理系统模块
module int_processing_system #(
    parameter GROUPS = 2,
    parameter WIDTH = 4
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [GROUPS*WIDTH-1:0] int_signals,
    input  wire [GROUPS-1:0]      group_enable,
    output wire [GROUPS-1:0]      group_interrupt
);

    // 组中断管理器实例化
    genvar g;
    generate
        for (g = 0; g < GROUPS; g = g + 1) begin: int_group_gen
            group_interrupt_manager #(
                .WIDTH(WIDTH)
            ) group_manager (
                .clk(clk),
                .rst(rst),
                .int_signals(int_signals[g*WIDTH +: WIDTH]),
                .group_enable(group_enable[g]),
                .group_interrupt(group_interrupt[g])
            );
        end
    endgenerate

endmodule

// 组中断管理器
module group_interrupt_manager #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] int_signals,
    input  wire             group_enable,
    output wire             group_interrupt
);

    // 内部连线
    wire int_detected;

    // 中断检测单元
    signal_detection_unit #(
        .WIDTH(WIDTH)
    ) detector (
        .input_signals(int_signals),
        .detection_result(int_detected)
    );
    
    // 中断启用单元
    interrupt_enable_unit enabler (
        .interrupt_input(int_detected),
        .enable_signal(group_enable),
        .interrupt_output(group_interrupt)
    );

endmodule

// 信号检测单元 - 优化逻辑以减少功耗
module signal_detection_unit #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] input_signals,
    output wire             detection_result
);

    // 使用归约或运算符检测任何输入信号
    assign detection_result = |input_signals;

endmodule

// 中断启用单元 - 优化时序性能
module interrupt_enable_unit (
    input  wire interrupt_input,
    input  wire enable_signal,
    output wire interrupt_output
);

    // 根据使能信号屏蔽中断
    assign interrupt_output = interrupt_input & enable_signal;

endmodule