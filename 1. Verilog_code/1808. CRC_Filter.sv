module CRC_Filter #(parameter POLY=16'h8005) (
    input clk,
    input [7:0] data_in,
    output reg [15:0] crc_out
);
    wire [15:0] crc_next = {crc_out[7:0], 8'h00} ^ ((data_in ^ crc_out[15:8]) << 8);
    always @(posedge clk) begin
        crc_out <= crc_next ^ ((POLY & {16{crc_next[15]}}));
    end
endmodule