module decoder_mask #(BASE_ADDR=32'h4000_0000, ADDR_MASK=32'hFFFF_0000) (
    input [31:0] addr,
    output reg select
);
always @* begin
    select = ((addr & ADDR_MASK) == BASE_ADDR);
end
endmodule