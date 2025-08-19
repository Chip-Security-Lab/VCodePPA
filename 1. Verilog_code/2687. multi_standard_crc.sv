module multi_standard_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [1:0] crc_type, // 00: CRC8, 01: CRC16, 10: CRC32
    output reg [31:0] crc_out
);
    localparam [7:0] POLY8 = 8'hD5;
    localparam [15:0] POLY16 = 16'h1021;
    localparam [31:0] POLY32 = 32'h04C11DB7;
    
    always @(posedge clk) begin
        if (rst) crc_out <= 32'h0;
        else begin
            case (crc_type)
                2'b00: crc_out[7:0] <= {crc_out[6:0], 1'b0} ^ 
                                     ((crc_out[7] ^ data[0]) ? POLY8 : 8'h0);
                2'b01: crc_out[15:0] <= {crc_out[14:0], 1'b0} ^ 
                                      ((crc_out[15] ^ data[0]) ? POLY16 : 16'h0);
                2'b10: crc_out <= {crc_out[30:0], 1'b0} ^ 
                                ((crc_out[31] ^ data[0]) ? POLY32 : 32'h0);
            endcase
        end
    end
endmodule