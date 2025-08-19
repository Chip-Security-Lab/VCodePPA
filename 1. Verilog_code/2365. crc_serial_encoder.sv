module crc_serial_encoder #(parameter DW=16)(
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    output reg serial_out
);
reg [4:0] crc_reg;
reg [DW+4:0] shift_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 0;
        crc_reg <= 5'h1F;
    end else if (en) begin
        shift_reg <= {data_in, crc_reg};
        crc_reg <= crc_reg ^ shift_reg[DW+4:5];
    end else begin
        shift_reg <= shift_reg << 1;
        serial_out <= shift_reg[DW+4];
    end
end
endmodule
