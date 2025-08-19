module crc8_serial (
    input clk, rst_n, en,
    input [7:0] data_in,
    output reg [7:0] crc_out
);
parameter POLY = 8'h07;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) crc_out <= 8'hFF;
    else if (en) begin
        crc_out <= {crc_out[6:0], 1'b0} ^ 
                  (crc_out[7] ? (POLY ^ {data_in, 1'b0}) : {data_in, 1'b0});
    end
end
endmodule