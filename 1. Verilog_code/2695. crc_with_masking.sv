module crc_with_masking(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] mask,
    input wire data_valid,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'h07;
    wire [7:0] masked_data = data & mask;
    always @(posedge clk) begin
        if (rst) crc <= 8'h00;
        else if (data_valid) begin
            crc <= {crc[6:0], 1'b0} ^ ((crc[7] ^ masked_data[0]) ? POLY : 8'h00);
        end
    end
endmodule