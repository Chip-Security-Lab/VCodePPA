module programmable_poly_crc(
    input wire clk,
    input wire rst,
    input wire [15:0] poly_in,
    input wire poly_load,
    input wire [7:0] data,
    input wire data_valid,
    output reg [15:0] crc
);
    reg [15:0] polynomial;
    always @(posedge clk) begin
        if (rst) begin
            polynomial <= 16'h1021; // Default CCITT
            crc <= 16'hFFFF;
        end else if (poly_load) polynomial <= poly_in;
        else if (data_valid) begin
            crc <= {crc[14:0], 1'b0} ^ ((crc[15] ^ data[0]) ? polynomial : 16'h0000);
        end
    end
endmodule