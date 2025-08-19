//SystemVerilog
module MuxDemux #(parameter W=8) (
    input [W-1:0] tx_data,
    output reg [3:0][W-1:0] rx_data,
    input [1:0] mode,
    input dir
);

wire [W-1:0] tx_data_shifted;
wire [3:0][W-1:0] rx_data_temp;

assign tx_data_shifted = tx_data >> 4;

always @(*) begin
    if (dir) begin
        case (mode)
            2'b00: rx_data = {4{tx_data}};
            2'b01: rx_data = {tx_data, tx_data_shifted};
            default: rx_data = 0;
        endcase
    end else begin
        rx_data = 0;
    end
end

endmodule