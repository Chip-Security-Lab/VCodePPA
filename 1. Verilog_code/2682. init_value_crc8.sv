module init_value_crc8(
    input wire clock,
    input wire resetn,
    input wire [7:0] init_value,
    input wire init_load,
    input wire [7:0] data,
    input wire data_valid,
    output reg [7:0] crc_out
);
    parameter [7:0] POLYNOMIAL = 8'hD5;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) crc_out <= 8'h00;
        else if (init_load) crc_out <= init_value;
        else if (data_valid) begin
            crc_out <= {crc_out[6:0], 1'b0} ^ 
                      ((crc_out[7] ^ data[0]) ? POLYNOMIAL : 8'h00);
        end
    end
endmodule
