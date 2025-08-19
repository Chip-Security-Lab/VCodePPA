module range_decoder(
    input [7:0] addr,
    output reg rom_sel,
    output reg ram_sel,
    output reg io_sel,
    output reg error
);
    always @(*) begin
        rom_sel = 1'b0; ram_sel = 1'b0; io_sel = 1'b0; error = 1'b0;
        if (addr < 8'h40)
            rom_sel = 1'b1;
        else if (addr < 8'hC0)
            ram_sel = 1'b1;
        else if (addr < 8'hFF)
            io_sel = 1'b1;
        else
            error = 1'b1;
    end
endmodule