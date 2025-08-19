//SystemVerilog
// 顶层模块
module Demux_TriState #(parameter DW=8, N=4) (
    inout [DW-1:0] bus,
    input [N-1:0] sel,
    input oe,
    output [N-1:0][DW-1:0] rx_data,
    input [N-1:0][DW-1:0] tx_data
);

    wire [DW-1:0] bus_out;

    // 发送数据子模块实例化
    TxDataSelector #(
        .DW(DW),
        .N(N)
    ) tx_selector_inst (
        .tx_data(tx_data),
        .sel(sel),
        .oe(oe),
        .bus_out(bus_out)
    );

    // 总线驱动
    assign bus = bus_out;

    // 接收数据子模块实例化
    RxDataDistributor #(
        .DW(DW),
        .N(N)
    ) rx_distributor_inst (
        .bus(bus),
        .sel(sel),
        .rx_data(rx_data)
    );

endmodule

// 发送数据选择器子模块
module TxDataSelector #(parameter DW=8, N=4) (
    input [N-1:0][DW-1:0] tx_data,
    input [N-1:0] sel,
    input oe,
    output reg [DW-1:0] bus_out
);

    // 总线驱动逻辑，基于选择信号选择发送数据
    always @(*) begin
        if (oe) begin
            bus_out = {DW{1'b0}};
            for (int i = 0; i < N; i = i + 1) begin
                if (sel == i) begin
                    bus_out = tx_data[i];
                end
            end
        end else begin
            bus_out = {DW{1'bz}};
        end
    end

endmodule

// 接收数据分配器子模块
module RxDataDistributor #(parameter DW=8, N=4) (
    input [DW-1:0] bus,
    input [N-1:0] sel,
    output reg [N-1:0][DW-1:0] rx_data
);

    // 接收数据逻辑，将总线数据分配到选定通道
    always @(*) begin
        for (int j = 0; j < N; j = j + 1) begin
            if (sel == j) begin
                rx_data[j] = bus;
            end else begin
                rx_data[j] = {DW{1'b0}};
            end
        end
    end

endmodule