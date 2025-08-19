//SystemVerilog
module decoder_async #(ADDR_WIDTH=3) (
    input [ADDR_WIDTH-1:0] addr,
    output [7:0] decoded
);

// Address decoder submodule
decoder_core #(
    .ADDR_WIDTH(ADDR_WIDTH)
) decoder_inst (
    .addr(addr),
    .decoded(decoded)
);

endmodule

module decoder_core #(ADDR_WIDTH=3) (
    input [ADDR_WIDTH-1:0] addr,
    output reg [7:0] decoded
);

// LUT-based decoder implementation
reg [7:0] lut [0:7];

initial begin
    lut[0] = 8'b00000001;
    lut[1] = 8'b00000010;
    lut[2] = 8'b00000100;
    lut[3] = 8'b00001000;
    lut[4] = 8'b00010000;
    lut[5] = 8'b00100000;
    lut[6] = 8'b01000000;
    lut[7] = 8'b10000000;
end

always @* begin
    decoded = lut[addr];
end

endmodule