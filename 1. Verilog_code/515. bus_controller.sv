module bus_controller(
    inout [7:0] bus,
    input dir,  // 方向控制
    input [7:0] tx_data,
    output [7:0] rx_data
);
    assign bus = dir ? tx_data : 8'bz;
    assign rx_data = bus;
endmodule