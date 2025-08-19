module Demux_MultiProto #(parameter DW=8) (
    input clk,
    input [1:0] proto_sel, // 0:SPI,1:I2C,2:UART
    input [DW-1:0] data,
    output reg [2:0][DW-1:0] proto_out
);
always @(posedge clk) begin
    proto_out <= 0;
    case(proto_sel)
        0: proto_out[0] <= data;   // SPI
        1: proto_out[1] <= data;   // I2C
        2: proto_out[2] <= data;   // UART
    endcase
end
endmodule
