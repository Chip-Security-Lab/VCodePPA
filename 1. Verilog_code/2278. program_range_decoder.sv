module program_range_decoder(
    input [7:0] addr,
    input [7:0] base_addr,
    input [7:0] limit,
    output in_range
);
    assign in_range = (addr >= base_addr) && (addr < (base_addr + limit));
endmodule