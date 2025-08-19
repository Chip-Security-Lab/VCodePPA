module CRCRecovery #(parameter WIDTH=8) (
    input clk, 
    input [WIDTH+3:0] coded_in, // 4-bit CRC
    output reg [WIDTH-1:0] data_out,
    output reg crc_error
);
    wire [3:0] calc_crc = coded_in[WIDTH+3:WIDTH] ^ coded_in[WIDTH-1:0];
    always @(posedge clk) begin
        crc_error <= |calc_crc;
        data_out <= crc_error ? 8'hFF : coded_in[WIDTH-1:0];
    end
endmodule
