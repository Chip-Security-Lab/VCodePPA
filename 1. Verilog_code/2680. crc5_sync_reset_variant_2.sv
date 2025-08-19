//SystemVerilog
module crc5_sync_reset(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [4:0] data,
    output reg [4:0] crc
);
    parameter [4:0] POLY = 5'h05; // CRC-5-USB: x^5 + x^2 + 1
    
    // Buffer registers for high fanout signals
    reg [4:0] crc_buf1;
    reg [4:0] crc_buf2;
    
    // Intermediate signals to reduce combinational path delay
    wire feedback = data[4] ^ crc_buf1[4];
    
    always @(posedge clk) begin
        if (rst) begin
            crc <= 5'h1F;
            crc_buf1 <= 5'h1F;
            crc_buf2 <= 5'h1F;
        end else if (en) begin
            // Pipeline the CRC calculation with buffered values
            crc[0] <= feedback;
            crc[1] <= crc_buf2[0];
            crc[2] <= crc_buf2[1] ^ feedback;
            crc[3] <= crc_buf2[2];
            crc[4] <= crc_buf2[3];
            
            // Update buffer registers
            crc_buf1 <= crc;
            crc_buf2 <= crc_buf1;
        end
    end
endmodule