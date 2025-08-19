module TreeMux #(parameter DW=8, N=8) (
    input [N-1:0][DW-1:0] din,
    input [$clog2(N)-1:0] sel,
    output [DW-1:0] dout
);
generate
    if(N == 1) assign dout = din[0];
    else begin
        wire [DW-1:0] low = din[sel[$clog2(N)-1:1]]; 
        wire [DW-1:0] high = din[sel];
        assign dout = sel[0] ? high : low;
    end
endgenerate
endmodule