//SystemVerilog
module MuxDemux #(parameter W=8) (
    input [W-1:0] tx_data,
    output reg [3:0][W-1:0] rx_data,
    input [1:0] mode,
    input dir
);

always @(*) begin
    case({dir, mode})
        3'b100: rx_data = {4{tx_data}};
        3'b101: rx_data = {tx_data, tx_data>>4};
        default: rx_data = 0;
    endcase
end

endmodule