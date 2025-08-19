//SystemVerilog
module async_bridge #(parameter WIDTH=8) (
    input [WIDTH-1:0] a_data,
    input a_valid, b_ready,
    output reg [WIDTH-1:0] b_data,
    output reg a_ready, b_valid
);

    // 实例化数据转换子模块
    data_converter #(.WIDTH(WIDTH)) data_conv (
        .a_data(a_data),
        .b_data(b_data)
    );

    // 实例化控制信号子模块
    control_signal #(.WIDTH(WIDTH)) ctrl_sig (
        .a_valid(a_valid),
        .b_ready(b_ready),
        .a_ready(a_ready),
        .b_valid(b_valid)
    );

endmodule

// 数据转换子模块
module data_converter #(parameter WIDTH=8) (
    input [WIDTH-1:0] a_data,
    output reg [WIDTH-1:0] b_data
);

    reg [WIDTH-1:0] b_data_temp;
    reg borrow;

    always @(*) begin
        {borrow, b_data_temp} = {1'b0, a_data} - 1;
        b_data = b_data_temp;
    end

endmodule

// 控制信号子模块
module control_signal #(parameter WIDTH=8) (
    input a_valid, b_ready,
    output reg a_ready, b_valid
);

    always @(*) begin
        b_valid = a_valid;
        a_ready = b_ready;
    end

endmodule