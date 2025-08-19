module bitserial_crc(
    input wire clk,
    input wire rst,
    input wire bit_in,
    input wire bit_valid,
    output reg [7:0] crc8_out
);
    parameter CRC_POLY = 8'h07; // x^8 + x^2 + x + 1
    wire feedback = crc8_out[7] ^ bit_in;
    always @(posedge clk) begin
        if (rst) crc8_out <= 8'h00;
        else if (bit_valid)
            crc8_out <= {crc8_out[6:0], 1'b0} ^ (feedback ? CRC_POLY : 8'h00);
    end
endmodule