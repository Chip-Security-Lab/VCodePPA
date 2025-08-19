module CascadeMux #(parameter DW=8) (
    input [1:0] sel1, sel2,
    input [3:0][DW-1:0] stage1,
    input [3:0][DW-1:0] stage2,
    output [DW-1:0] out
);
wire [DW-1:0] m1 = stage1[sel1];
wire [DW-1:0] m2 = stage2[sel2];
assign out = sel1[0] ? m2 : m1;
endmodule