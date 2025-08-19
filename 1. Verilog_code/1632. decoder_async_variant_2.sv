//SystemVerilog
module decoder_async #(ADDR_WIDTH=3) (
    input [ADDR_WIDTH-1:0] addr,
    output [7:0] decoded
);

// Address decoder core
decoder_core #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_decoder_core (
    .addr(addr),
    .decoded(decoded)
);

endmodule

module decoder_core #(ADDR_WIDTH=3) (
    input [ADDR_WIDTH-1:0] addr,
    output reg [7:0] decoded
);

// Decoder logic
always @* begin
    decoded = 8'b0;
    decoded[addr] = 1'b1;
end

endmodule