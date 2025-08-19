module decoder_crc #(AW=8, DW=8) (
    input [AW-1:0] addr,
    input [DW-1:0] data,
    output reg select
);
wire [7:0] crc = addr ^ data;
always @* begin
    select = (addr[7:4] == 4'b1010) && (crc == 8'h55);
end
endmodule