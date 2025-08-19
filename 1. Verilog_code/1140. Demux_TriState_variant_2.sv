//SystemVerilog
// 顶层模块
module Demux_TriState #(
    parameter DW = 8,  // 数据宽度
    parameter N = 4    // 选择线数量
)(
    inout [DW-1:0] bus,
    input [N-1:0] sel,
    input oe,
    output [N-1:0][DW-1:0] rx_data,
    input [N-1:0][DW-1:0] tx_data
);
    // 内部连线
    wire [DW-1:0] bus_out;
    
    // 发送器子模块实例化
    Bus_Transmitter #(
        .DW(DW),
        .N(N)
    ) tx_inst (
        .tx_data(tx_data),
        .sel(sel),
        .oe(oe),
        .bus_out(bus_out)
    );
    
    // 接收器子模块实例化
    Bus_Receiver #(
        .DW(DW),
        .N(N)
    ) rx_inst (
        .bus_in(bus),
        .sel(sel),
        .rx_data(rx_data)
    );
    
    // 三态总线控制
    assign bus = oe ? bus_out : {DW{1'bz}};
    
endmodule

// 发送器子模块 - 处理输出数据选择
module Bus_Transmitter #(
    parameter DW = 8,  // 数据宽度
    parameter N = 4    // 选择线数量
)(
    input [N-1:0][DW-1:0] tx_data,
    input [N-1:0] sel,
    input oe,
    output [DW-1:0] bus_out
);
    // 优化选择逻辑，根据选择线选择对应输出数据
    reg [DW-1:0] selected_data;
    
    // 数据选择逻辑
    always @(*) begin
        selected_data = tx_data[sel];
    end
    
    // 输出控制逻辑
    assign bus_out = selected_data;
    
endmodule

// 接收器子模块 - 处理数据分发
module Bus_Receiver #(
    parameter DW = 8,  // 数据宽度
    parameter N = 4    // 选择线数量
)(
    input [DW-1:0] bus_in,
    input [N-1:0] sel,
    output reg [N-1:0][DW-1:0] rx_data
);
    // 将大型的always块拆分为更小的功能块
    
    // 清零逻辑：将所有输出端口初始化为0
    integer i;
    always @(*) begin
        for (i = 0; i < N; i = i + 1) begin
            rx_data[i] = {DW{1'b0}};
        end
    end
    
    // 数据分发逻辑：根据选择信号将数据分发到选定的输出端口
    always @(*) begin
        if (sel < N) begin  // 添加边界检查，提高鲁棒性
            rx_data[sel] = bus_in;
        end
    end
    
endmodule