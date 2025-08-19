//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// 顶层模块: 数据加扰器
///////////////////////////////////////////////////////////////////////////////
module data_scrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk,
    input  wire reset,
    input  wire data_in,
    input  wire [POLY_WIDTH-1:0] polynomial,  // 可配置多项式
    input  wire [POLY_WIDTH-1:0] initial_state,
    input  wire load_init,
    output wire data_out
);
    // 内部信号
    wire [POLY_WIDTH-1:0] lfsr_state;
    wire feedback;
    
    // LFSR控制模块实例
    lfsr_controller #(
        .WIDTH(POLY_WIDTH)
    ) lfsr_ctrl_inst (
        .clk(clk),
        .reset(reset),
        .polynomial(polynomial),
        .initial_state(initial_state),
        .load_init(load_init),
        .feedback(feedback),
        .lfsr_state(lfsr_state)
    );
    
    // 反馈计算模块实例
    feedback_calculator #(
        .WIDTH(POLY_WIDTH)
    ) feedback_calc_inst (
        .lfsr_state(lfsr_state),
        .polynomial(polynomial),
        .feedback(feedback)
    );
    
    // 数据处理模块实例
    data_processor data_proc_inst (
        .data_in(data_in),
        .lfsr_lsb(lfsr_state[0]),
        .data_out(data_out)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块1: LFSR控制器 - 负责LFSR寄存器的更新和控制
///////////////////////////////////////////////////////////////////////////////
module lfsr_controller #(parameter WIDTH = 7) (
    input  wire clk,
    input  wire reset,
    input  wire [WIDTH-1:0] polynomial,
    input  wire [WIDTH-1:0] initial_state,
    input  wire load_init,
    input  wire feedback,
    output reg  [WIDTH-1:0] lfsr_state
);
    // 使用二段式状态寄存器提高时序性能
    always @(posedge clk) begin
        if (reset)
            lfsr_state <= {WIDTH{1'b1}};  // 非零默认值
        else if (load_init)
            lfsr_state <= initial_state;
        else
            lfsr_state <= {feedback, lfsr_state[WIDTH-1:1]};
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块2: 反馈计算器 - 计算LFSR的反馈值
///////////////////////////////////////////////////////////////////////////////
module feedback_calculator #(parameter WIDTH = 7) (
    input  wire [WIDTH-1:0] lfsr_state,
    input  wire [WIDTH-1:0] polynomial,
    output wire feedback
);
    // 使用参数化的异或运算来计算反馈
    // 通过AND操作选择参与反馈计算的位，然后进行异或
    assign feedback = ^(lfsr_state & polynomial);
endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块3: 数据处理器 - 执行数据加扰操作
///////////////////////////////////////////////////////////////////////////////
module data_processor (
    input  wire data_in,
    input  wire lfsr_lsb,
    output wire data_out
);
    // 将输入数据与LFSR的最低有效位进行异或运算以实现加扰
    assign data_out = data_in ^ lfsr_lsb;
endmodule