//SystemVerilog
module AddrDecMux #(parameter AW=4, DW=8) (
    input  [AW-1:0] addr,
    output reg [(2**AW)*DW-1:0] data_out,
    input  [DW-1:0] data_in
);
    integer idx;
    always @(*) begin
        data_out = {((2**AW)*DW){1'b0}};
        idx = 0;
        while (idx < 2**AW) begin
            if (addr == idx)
                data_out[(idx*DW) +: DW] = data_in;
            idx = idx + 1;
        end
    end
endmodule