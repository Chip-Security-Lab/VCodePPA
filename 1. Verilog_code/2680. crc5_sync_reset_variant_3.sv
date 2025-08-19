//SystemVerilog
module crc5_sync_reset(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [4:0] data,
    output reg [4:0] crc
);
    parameter [4:0] POLY = 5'h05; // CRC-5-USB: x^5 + x^2 + 1
    
    // Buffered crc signals to reduce fanout
    reg [4:0] crc_buf1, crc_buf2;
    
    always @(posedge clk) begin
        if (rst) begin
            crc <= 5'h1F;
            crc_buf1 <= 5'h1F;
            crc_buf2 <= 5'h1F;
        end
        else if (en) begin
            // Update buffer registers first
            crc_buf1 <= crc;
            crc_buf2 <= crc;
            
            // Use buffered signals to reduce fanout on critical paths
            crc[0] <= data[4] ^ crc_buf1[4];
            crc[1] <= crc_buf1[0];
            crc[2] <= crc_buf1[1] ^ (data[4] ^ crc_buf2[4]);
            crc[3] <= crc_buf2[2];
            crc[4] <= crc_buf2[3];
        end
    end
endmodule