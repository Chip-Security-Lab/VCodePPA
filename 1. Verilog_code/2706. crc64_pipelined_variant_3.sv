//SystemVerilog
module crc64_pipelined (
    input clk, en,
    input [63:0] data,
    output reg [63:0] crc
);
parameter POLY = 64'h42F0E1EBA9EA3693;
reg [63:0] stage[0:3];

// Stage 0: Initial XOR with shifted CRC
always @(posedge clk) begin
    if (en) begin
        stage[0] <= data ^ {crc[56:0], 7'b0};
    end
end

// Stage 1: First polynomial reduction
always @(posedge clk) begin
    if (en) begin
        stage[1] <= stage[0] ^ (stage[0][63] ? POLY : 0);
    end
end

// Stage 2: Second polynomial reduction
always @(posedge clk) begin
    if (en) begin
        stage[2] <= stage[1] ^ (stage[1][63] ? POLY : 0);
    end
end

// Stage 3: Final polynomial reduction and output
always @(posedge clk) begin
    if (en) begin
        stage[3] <= stage[2] ^ (stage[2][63] ? POLY : 0);
        crc <= stage[3];
    end
end

endmodule