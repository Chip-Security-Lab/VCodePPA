module crc16_with_valid(
    input clk,
    input reset,
    input [7:0] data_in,
    input data_valid,
    output reg [15:0] crc,
    output reg crc_valid
);
    localparam POLY = 16'h1021;
    always @(posedge clk) begin
        if (reset) begin
            crc <= 16'hFFFF;
            crc_valid <= 1'b0;
        end else if (data_valid) begin
            crc <= {crc[14:0], 1'b0} ^ (crc[15] ? POLY : 16'h0000) ^ {8'h00, data_in};
            crc_valid <= 1'b1;
        end else crc_valid <= 1'b0;
    end
endmodule