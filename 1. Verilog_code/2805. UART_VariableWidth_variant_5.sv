//SystemVerilog
// UART_VariableWidth 顶层模块，实例化各功能子模块
module UART_VariableWidth #(
    parameter MAX_WIDTH = 9
)(
    input wire [3:0] data_width,              // 5-9位可配置
    input wire [7:0] rx_data,                 
    output wire [MAX_WIDTH-1:0] rx_extended,  // 扩展的接收数据
    input wire [MAX_WIDTH-1:0] tx_truncated,  // 发送数据输入
    output wire [1:0] stop_bits               // 停止位数
);

    // 接收数据扩展模块
    wire [MAX_WIDTH-1:0] rx_extended_internal;
    UART_ReceiveExtender #(
        .MAX_WIDTH(MAX_WIDTH)
    ) u_receive_extender (
        .data_width     (data_width),
        .rx_data        (rx_data),
        .tx_truncated   (tx_truncated),
        .rx_extended    (rx_extended_internal)
    );

    // 停止位选择模块
    wire [1:0] stop_bits_internal;
    UART_StopBitSelector u_stop_bit_selector (
        .data_width     (data_width),
        .stop_bits      (stop_bits_internal)
    );

    assign rx_extended = rx_extended_internal;
    assign stop_bits = stop_bits_internal;

endmodule

// -------------------------------------------------------------------------
// 子模块1：接收数据扩展模块
// 根据data_width扩展rx_data或直接传递tx_truncated
// -------------------------------------------------------------------------
module UART_ReceiveExtender #(
    parameter MAX_WIDTH = 9
)(
    input wire [3:0] data_width,                // 数据宽度选择
    input wire [7:0] rx_data,                   // 原始接收数据
    input wire [MAX_WIDTH-1:0] tx_truncated,    // 发送数据（9位时传递）
    output reg [MAX_WIDTH-1:0] rx_extended      // 扩展后的接收数据
);
    always @(*) begin
        case(data_width)
            4'd5: rx_extended = {4'b0, rx_data[4:0]};
            4'd6: rx_extended = {3'b0, rx_data[5:0]};
            4'd7: rx_extended = {2'b0, rx_data[6:0]};
            4'd8: rx_extended = {1'b0, rx_data[7:0]};
            4'd9: rx_extended = tx_truncated; // 9位时直接传递
            default: rx_extended = {1'b0, rx_data}; // 默认8位
        endcase
    end
endmodule

// -------------------------------------------------------------------------
// 子模块2：停止位选择模块
// 根据data_width决定停止位数
// -------------------------------------------------------------------------
module UART_StopBitSelector(
    input wire [3:0] data_width,    // 数据宽度选择
    output reg [1:0] stop_bits      // 停止位数
);
    always @(*) begin
        if (data_width > 8) begin
            stop_bits = 2'd2;
        end else begin
            stop_bits = 2'd1;
        end
    end
endmodule