module decoder_range #(MIN=8'h20, MAX=8'h3F) (
    input [7:0] addr,
    output reg active
);
always @* begin
    active = (addr >= MIN) && (addr <= MAX);
end
endmodule