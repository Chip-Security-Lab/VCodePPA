module AddrDecMux #(parameter AW=4, DW=8) (
    input [AW-1:0] addr,
    output [(2**AW)*DW-1:0] data_out, // 改为一维数组
    input [DW-1:0] data_in
);
genvar i;
generate
    for(i=0; i<2**AW; i=i+1) begin: dec_loop
        assign data_out[(i*DW) +: DW] = (addr == i) ? data_in : {DW{1'b0}}; // 使用位选择操作符
    end
endgenerate
endmodule