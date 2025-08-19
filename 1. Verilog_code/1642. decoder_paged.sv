module decoder_paged #(PAGE_BITS=2) (
    input [7:0] addr,
    input [PAGE_BITS-1:0] page_reg,
    output reg [3:0] select
);
always @* begin
    select = (addr[7:8-PAGE_BITS] == page_reg) ? 
            (1 << addr[7-PAGE_BITS:4]) : 4'b0;
end
endmodule