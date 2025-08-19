module auto_poly_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] data_len,
    output reg [15:0] crc_out
);
    reg [15:0] polynomial;
    always @(*) begin
        case (data_len)
            8'd8:    polynomial = 16'h0007; // 8-bit CRC
            8'd16:   polynomial = 16'h8005; // 16-bit CRC
            default: polynomial = 16'h1021; // CCITT
        endcase
    end
    always @(posedge clk) begin
        if (rst) crc_out <= 16'h0000;
        else begin
            crc_out <= {crc_out[14:0], 1'b0} ^ 
                     ((crc_out[15] ^ data[0]) ? polynomial : 16'h0000);
        end
    end
endmodule