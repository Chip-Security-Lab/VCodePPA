module UART_VariableWidth #(
    parameter MAX_WIDTH = 9
)(
    input wire [3:0] data_width,  // 5-9位可配置
    input wire [7:0] rx_data,     
    output reg [MAX_WIDTH-1:0] rx_extended,
    input wire [MAX_WIDTH-1:0] tx_truncated,
    output wire [1:0] stop_bits   
);
// 动态位选择逻辑
wire [7:0] rx_core;
wire [MAX_WIDTH-1:0] tx_core;

// 修复：正确连接线网
assign rx_core = rx_data;
assign tx_core = tx_truncated;

always @(*) begin
    case(data_width)
        4'd5: rx_extended = {4'b0, rx_core[4:0]};
        4'd6: rx_extended = {3'b0, rx_core[5:0]};
        4'd7: rx_extended = {2'b0, rx_core[6:0]};
        4'd8: rx_extended = {1'b0, rx_core[7:0]};
        4'd9: rx_extended = tx_truncated; // 直接传递9位数据
        default: rx_extended = {1'b0, rx_core}; // 默认8位
    endcase
end

// 动态停止位生成
assign stop_bits = (data_width > 8) ? 2'd2 : 2'd1;
endmodule