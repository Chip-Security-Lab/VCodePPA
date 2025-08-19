module mem_mapped_decoder(
    input [7:0] addr,
    input [1:0] bank_sel,
    output reg [3:0] chip_sel
);
    always @(*) begin
        chip_sel = 4'b0000;
        if (addr >= 8'h00 && addr <= 8'h7F)
            chip_sel[bank_sel] = 1'b1;
    end
endmodule