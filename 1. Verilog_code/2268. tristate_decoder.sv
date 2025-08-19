module tristate_decoder(
    input [1:0] addr,
    input enable,
    output [3:0] select
);
    assign select[0] = enable ? (addr == 2'b00) : 1'bz;
    assign select[1] = enable ? (addr == 2'b01) : 1'bz;
    assign select[2] = enable ? (addr == 2'b10) : 1'bz;
    assign select[3] = enable ? (addr == 2'b11) : 1'bz;
endmodule