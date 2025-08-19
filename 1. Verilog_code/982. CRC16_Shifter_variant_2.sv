//SystemVerilog
module CRC16_Shifter #(parameter POLY=16'h8005) (
    input clk,
    input rst,
    input serial_in,
    output reg [15:0] crc_out
);

reg serial_in_d;
wire [15:0] next_crc;

assign next_crc = {crc_out[14:0], 1'b0} ^ (POLY & {16{crc_out[15] ^ serial_in_d}});

always @(posedge clk or posedge rst) begin
    if (rst) begin
        serial_in_d <= 1'b0;
        crc_out <= 16'hFFFF;
    end else begin
        serial_in_d <= serial_in;
        crc_out <= next_crc;
    end
end

endmodule