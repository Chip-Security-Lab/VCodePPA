module decoder_async #(parameter AW=4, DW=16) (
    input [AW-1:0] addr,
    output [DW-1:0] decoded
);
    assign decoded = (addr < DW) ? (1'b1 << addr) : {DW{1'b0}};
endmodule