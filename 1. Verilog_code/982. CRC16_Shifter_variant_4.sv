//SystemVerilog
module CRC16_Shifter #(parameter POLY = 16'h8005) (
    input clk,
    input rst,
    input serial_in,
    output reg [15:0] crc_out
);
    wire feedback;
    reg [15:0] next_crc;

    assign feedback = crc_out[15] ^ serial_in;

    always @(*) begin
        next_crc[0]  = crc_out[15] ^ serial_in;
        next_crc[1]  = crc_out[0];
        next_crc[2]  = crc_out[1];
        next_crc[3]  = crc_out[2];
        next_crc[4]  = crc_out[3];
        next_crc[5]  = crc_out[4] ^ feedback;
        next_crc[6]  = crc_out[5];
        next_crc[7]  = crc_out[6];
        next_crc[8]  = crc_out[7];
        next_crc[9]  = crc_out[8];
        next_crc[10] = crc_out[9];
        next_crc[11] = crc_out[10];
        next_crc[12] = crc_out[11];
        next_crc[13] = crc_out[12];
        next_crc[14] = crc_out[13];
        next_crc[15] = crc_out[14] ^ feedback;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_out <= 16'hFFFF;
        end else begin
            crc_out <= next_crc;
        end
    end
endmodule