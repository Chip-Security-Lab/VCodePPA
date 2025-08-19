module CaseMux #(parameter N=4, DW=8) (
    input [$clog2(N)-1:0] sel,
    input [N-1:0][DW-1:0] din,
    output reg [DW-1:0] dout
);
always @* 
    case(sel)
        default: dout = din[sel];
    endcase
endmodule