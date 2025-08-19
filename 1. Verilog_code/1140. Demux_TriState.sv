module Demux_TriState #(parameter DW=8, N=4) (
    inout [DW-1:0] bus,
    input [N-1:0] sel,
    input oe,
    output [N-1:0][DW-1:0] rx_data,
    input [N-1:0][DW-1:0] tx_data
);
assign bus = oe ? tx_data[sel] : {DW{1'bz}};
generate genvar i;
for(i=0; i<N; i=i+1) begin
    assign rx_data[i] = (sel == i) ? bus : 0; 
end
endgenerate
endmodule
