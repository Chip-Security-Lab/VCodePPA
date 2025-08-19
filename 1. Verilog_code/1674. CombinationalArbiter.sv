module CombinationalArbiter #(parameter N=4) (
    input [N-1:0] req,
    output [N-1:0] grant
);
wire [N-1:0] mask = req - 1;
assign grant = req & ~mask;
endmodule
