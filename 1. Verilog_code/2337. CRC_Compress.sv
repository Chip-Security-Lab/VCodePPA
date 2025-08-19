module CRC_Compress #(POLY=32'h04C11DB7) (
    input clk, en,
    input [31:0] data,
    output reg [31:0] crc
);
always @(posedge clk) if(en) begin
    crc <= {crc[23:0], 1'b0} ^ ((crc[31]^data[31]) ? POLY : 0);
end
endmodule
