//SystemVerilog
module AddrDecMux #(parameter AW = 4, DW = 8) (
    input  [AW-1:0] addr,
    output [(2**AW)*DW-1:0] data_out,
    input  [DW-1:0] data_in
);
    wire [(2**AW)-1:0] addr_decode;
    assign addr_decode = 1'b1 << addr;

    genvar i;
    generate
        for (i = 0; i < 2**AW; i = i + 1) begin: dec_loop
            assign data_out[(i*DW) +: DW] = addr_decode[i] ? data_in : {DW{1'b0}};
        end
    endgenerate
endmodule