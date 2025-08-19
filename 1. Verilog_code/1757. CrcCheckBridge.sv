module CrcCheckBridge #(
    parameter DATA_W = 32,
    parameter CRC_W = 8
)(
    input clk, rst_n,
    input [DATA_W-1:0] data_in,
    input data_valid,
    output reg [DATA_W-1:0] data_out,
    output reg crc_error
);
    reg [CRC_W-1:0] crc_calc;
    
    always @(posedge clk) begin
        if (data_valid) begin
            crc_calc <= ^{data_in, crc_calc} << 1;
            data_out <= data_in;
        end
        crc_error <= (crc_calc != 0) & data_valid;
    end
endmodule