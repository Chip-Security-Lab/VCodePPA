module Demux_Priority #(parameter DW=4) (
    input [DW-1:0] data_in,
    input [3:0] sel,
    output reg [15:0][DW-1:0] data_out
);
always @(*) begin
    data_out = 0;
    casez (sel)
        4'b1???: data_out[15] = data_in;
        4'b01??: data_out[7]  = data_in;
        4'b001?: data_out[3]  = data_in;
        4'b0001: data_out[1]  = data_in;
        default: data_out[0]  = data_in;
    endcase
end
endmodule