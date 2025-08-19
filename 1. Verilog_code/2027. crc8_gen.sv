module crc8_gen (
    input clk, rst_n,
    input [7:0] data_in,
    output reg [7:0] crc_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) crc_out <= 0;
        else begin
            crc_out <= crc_out ^ data_in;
            crc_out <= {crc_out[6:0], 1'b0} ^ (crc_out[7] ? 8'h07 : 0);
        end
    end
endmodule