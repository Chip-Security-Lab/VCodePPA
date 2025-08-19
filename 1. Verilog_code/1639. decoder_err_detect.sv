module decoder_err_detect #(MAX_ADDR=16'hFFFF) (
    input [15:0] addr,
    output reg select,
    output reg err
);
always @* begin
    select = (addr < MAX_ADDR);
    err = (addr >= MAX_ADDR);
end
endmodule