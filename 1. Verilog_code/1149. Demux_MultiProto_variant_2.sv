//SystemVerilog
module Demux_MultiProto #(parameter DW=8) (
    input clk,
    input [1:0] proto_sel, // 0:SPI,1:I2C,2:UART
    input [DW-1:0] data,
    output reg [2:0][DW-1:0] proto_out
);
    always @(posedge clk) begin
        proto_out <= 0;
        if (proto_sel == 0) begin
            proto_out[0] <= data;   // SPI
        end else if (proto_sel == 1) begin
            proto_out[1] <= data;   // I2C
        end else if (proto_sel == 2) begin
            proto_out[2] <= data;   // UART
        end
    end
endmodule