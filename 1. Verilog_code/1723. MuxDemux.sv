module MuxDemux #(parameter W=8) (
    input [W-1:0] tx_data,
    output [3:0][W-1:0] rx_data,
    input [1:0] mode,
    input dir
);
assign rx_data = (dir && mode==0) ? {4{tx_data}} : 
                (dir && mode==1) ? {tx_data, tx_data>>4} : 0;
endmodule