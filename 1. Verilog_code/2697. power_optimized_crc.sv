module power_optimized_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire power_save,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'h07;
    wire gated_clk = clk & ~power_save;
    always @(posedge gated_clk or posedge rst) begin
        if (rst) crc <= 8'h00;
        else if (data_valid) begin
            crc <= {crc[6:0], 1'b0} ^ ((crc[7] ^ data[0]) ? POLY : 8'h00);
        end
    end
endmodule