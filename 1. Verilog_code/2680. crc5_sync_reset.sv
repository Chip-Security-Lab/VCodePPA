module crc5_sync_reset(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [4:0] data,
    output reg [4:0] crc
);
    parameter [4:0] POLY = 5'h05; // CRC-5-USB: x^5 + x^2 + 1
    always @(posedge clk) begin
        if (rst) crc <= 5'h1F;
        else if (en) begin
            crc[0] <= data[4] ^ crc[4];
            crc[1] <= crc[0];
            crc[2] <= crc[1] ^ (data[4] ^ crc[4]);
            crc[3] <= crc[2];
            crc[4] <= crc[3];
        end
    end
endmodule