module decoder_async #(ADDR_WIDTH=3) (
    input [ADDR_WIDTH-1:0] addr,
    output reg [7:0] decoded
);
always @* begin
    decoded = 8'b0;
    decoded[addr] = 1'b1;
end
endmodule