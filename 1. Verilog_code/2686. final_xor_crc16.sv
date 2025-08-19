module final_xor_crc16(
    input wire clk,
    input wire reset,
    input wire [7:0] data,
    input wire data_valid,
    input wire calc_done,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h1021;
    parameter [15:0] FINAL_XOR = 16'hFFFF;
    reg [15:0] crc_reg;
    always @(posedge clk) begin
        if (reset) begin
            crc_reg <= 16'h0000;
            crc_out <= 16'h0000;
        end else if (data_valid) begin
            crc_reg <= {crc_reg[14:0], 1'b0} ^ ((crc_reg[15] ^ data[0]) ? POLY : 16'h0);
        end else if (calc_done) begin
            crc_out <= crc_reg ^ FINAL_XOR;
        end
    end
endmodule