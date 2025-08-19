//SystemVerilog
// 顶层模块
module param_d_latch_top #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire enable,
    output wire [WIDTH-1:0] data_out
);

    // 实例化数据锁存子模块
    data_latch #(
        .WIDTH(WIDTH)
    ) data_latch_inst (
        .data_in(data_in),
        .enable(enable),
        .data_out(data_out)
    );

endmodule

// 数据锁存子模块
module data_latch #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire enable,
    output reg [WIDTH-1:0] data_out
);

    // 使用组合逻辑实现锁存功能
    always @* begin
        data_out = enable ? data_in : data_out;
    end

endmodule