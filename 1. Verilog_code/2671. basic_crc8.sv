module basic_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [7:0] crc_out
);
    parameter POLY = 8'hD5; // x^8 + x^7 + x^6 + x^4 + x^2 + 1
    always @(posedge clk) begin
        if (!rst_n) crc_out <= 8'h00;
        else if (data_valid) begin
            crc_out <= {crc_out[6:0], 1'b0} ^ 
                      ({8{crc_out[7]}} & POLY) ^ data_in;
        end
    end
endmodule