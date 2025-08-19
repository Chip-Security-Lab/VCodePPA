//SystemVerilog
// 顶层模块
module AsyncLatch #(parameter WIDTH=4) (
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    // 实例化数据锁存子模块
    DataLatch #(
        .WIDTH(WIDTH)
    ) data_latch_inst (
        .en(en),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule

// 数据锁存子模块
module DataLatch #(parameter WIDTH=4) (
    input en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    // 锁存逻辑
    always @* begin
        if(en) begin
            data_out = data_in;
        end
    end

endmodule