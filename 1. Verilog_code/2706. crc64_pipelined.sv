module crc64_pipelined (
    input clk, en,
    input [63:0] data,
    output reg [63:0] crc
);
parameter POLY = 64'h42F0E1EBA9EA3693;
reg [63:0] stage[0:3];

always @(posedge clk) begin
    if (en) begin
        stage[0] <= data ^ {crc[56:0], 7'b0};
        stage[1] <= stage[0] ^ (stage[0][63] ? POLY : 0);
        stage[2] <= stage[1] ^ (stage[1][63] ? POLY : 0);
        stage[3] <= stage[2] ^ (stage[2][63] ? POLY : 0);
        crc <= stage[3];
    end
end
endmodule