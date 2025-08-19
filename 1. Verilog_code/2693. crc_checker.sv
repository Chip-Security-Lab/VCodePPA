module crc_checker(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire [7:0] crc_in,
    input wire data_valid,
    output reg crc_valid,
    output reg [7:0] calculated_crc
);
    parameter [7:0] POLY = 8'hD5;
    always @(posedge clk) begin
        if (rst) begin
            calculated_crc <= 8'h00;
            crc_valid <= 1'b0;
        end else if (data_valid) begin
            calculated_crc <= {calculated_crc[6:0], 1'b0} ^ 
                            ((calculated_crc[7] ^ data_in[0]) ? POLY : 8'h00);
            crc_valid <= (calculated_crc == crc_in);
        end
    end
endmodule