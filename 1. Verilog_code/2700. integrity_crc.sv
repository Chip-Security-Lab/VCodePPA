module integrity_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    output reg [7:0] crc_value,
    output reg integrity_error
);
    parameter [7:0] POLY = 8'hD5;
    parameter [7:0] EXPECTED_CRC = 8'h00;
    reg [7:0] shadow_crc;
    
    always @(posedge clk) begin
        if (rst) begin
            crc_value <= 8'h00;
            shadow_crc <= 8'h00;
            integrity_error <= 1'b0;
        end else if (data_valid) begin
            crc_value <= {crc_value[6:0], 1'b0} ^ 
                       ((crc_value[7] ^ data[0]) ? POLY : 8'h00);
            shadow_crc <= {shadow_crc[6:0], 1'b0} ^ 
                        ((shadow_crc[7] ^ data[0]) ? POLY : 8'h00);
            integrity_error <= (crc_value != shadow_crc);
        end
    end
endmodule