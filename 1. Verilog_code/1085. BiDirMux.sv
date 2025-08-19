module BiDirMux #(parameter DW=8) (
    inout [DW-1:0] bus,
    input [(4*DW)-1:0] tx, // 改为一维数组
    output [(4*DW)-1:0] rx, // 改为一维数组
    input [1:0] sel, 
    input oe
);
genvar i;
generate
    for(i=0; i<4; i=i+1) begin: mux_block
        assign rx[(i+1)*DW-1:i*DW] = (sel == i) ? bus : {DW{1'bz}}; // 使用显式位宽
    end
endgenerate
assign bus = (oe) ? tx[(sel*DW) +: DW] : {DW{1'bz}}; // 使用位选择操作符
endmodule