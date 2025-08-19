module crc8_generator #(parameter DATA_W=8) (
    input clk, rst, en,
    input [DATA_W-1:0] data,
    output reg [7:0] crc
);
always @(posedge clk or posedge rst) begin
    if (rst) 
        crc <= 8'hFF;
    else if (en) 
        crc <= (crc << 1) ^ ((crc[7] ^ data[7]) ? 8'h07 : 0);
end
endmodule