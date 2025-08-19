module crc_error_flag (
    input clk, rst,
    input [15:0] data_in, expected_crc,
    output reg error_flag
);
reg [15:0] current_crc;

always @(posedge clk) begin
    if (rst) begin
        current_crc <= 16'hFFFF;
        error_flag <= 0;
    end else begin
        current_crc <= crc16_update(current_crc, data_in);
        error_flag <= (current_crc != expected_crc);
    end
end

function [15:0] crc16_update;
input [15:0] crc, data;
begin
    // CRC-16-CCITT 实现
    crc16_update = {crc[14:0], 1'b0} ^ 
                  (crc[15] ^ data[15] ? 16'h1021 : 0);
end
endfunction
endmodule