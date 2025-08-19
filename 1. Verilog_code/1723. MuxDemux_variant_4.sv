//SystemVerilog
module MuxDemux #(parameter W=8) (
    input [W-1:0] tx_data,
    output [3:0][W-1:0] rx_data,
    input [1:0] mode,
    input dir
);

wire [W-1:0] tx_data_shifted;
wire [3:0][W-1:0] mux_out;
wire [W-1:0] tx_data_comp;  // 补码形式
wire [W-1:0] tx_data_shifted_comp;  // 移位后的补码形式

// 计算补码
assign tx_data_comp = ~tx_data + 1'b1;
assign tx_data_shifted_comp = ~tx_data_shifted + 1'b1;

// Barrel shifter implementation
assign tx_data_shifted = {4'b0, tx_data[W-1:4]};

// Mux selection logic using complement addition
assign mux_out = (mode == 2'b00) ? {4{tx_data}} :
                (mode == 2'b01) ? {tx_data, tx_data_shifted} : 0;

// Direction control
assign rx_data = dir ? mux_out : 0;

endmodule