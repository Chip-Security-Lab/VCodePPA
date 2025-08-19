//SystemVerilog
module crc8_gen (
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] crc_out
);
    reg [7:0] crc_next;
    reg [7:0] crc_xor;

    always @(*) begin
        crc_xor = crc_out ^ data_in;
        crc_next = crc_xor[7] ? (({crc_xor[6:0], 1'b0}) ^ 8'h07) : {crc_xor[6:0], 1'b0};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            crc_out <= 8'd0;
        else
            crc_out <= crc_next;
    end
endmodule