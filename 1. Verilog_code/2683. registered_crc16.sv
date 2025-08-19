module registered_crc16(
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire calculate,
    output reg [15:0] crc_reg_out
);
    localparam [15:0] POLY = 16'h8005;
    reg [15:0] crc_temp;
    always @(posedge clk) begin
        if (rst) begin
            crc_temp <= 16'hFFFF;
            crc_reg_out <= 16'h0000;
        end else if (calculate) begin
            crc_temp <= crc_temp ^ data_in;
            crc_reg_out <= crc_temp;
        end
    end
endmodule