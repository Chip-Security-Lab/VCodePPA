module MuxParamAddr #(parameter W=8, ADDR_W=2) (
    input [(2**ADDR_W)-1:0][W-1:0] ch,
    input [ADDR_W-1:0] addr,
    output [W-1:0] out
);
assign out = ch[addr];
endmodule