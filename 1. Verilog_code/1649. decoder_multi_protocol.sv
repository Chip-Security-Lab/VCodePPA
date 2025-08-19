module decoder_multi_protocol (
    input [1:0] mode,
    input [15:0] addr,
    output reg [7:0] select
);
always @* begin
    case(mode)
        2'b00: select = (addr[15:12] == 4'h1) ? 8'h01 : 8'h00;  // I2C模式
        2'b01: select = (addr[7:5] == 3'b101) ? 8'h02 : 8'h00;  // SPI模式
        2'b10: select = (addr[11:8] > 4'h7) ? 8'h04 : 8'h00;    // AXI模式
        default: select = 8'h00;
    endcase
end
endmodule