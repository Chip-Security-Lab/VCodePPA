module CRC16_Shifter #(parameter POLY=16'h8005) (
    input clk, rst, serial_in,
    output reg [15:0] crc_out
);
always @(posedge clk or posedge rst) begin
    if (rst) crc_out <= 16'hFFFF;
    else crc_out <= {crc_out[14:0], 1'b0} ^ (POLY & {16{crc_out[15] ^ serial_in}});
end
endmodule