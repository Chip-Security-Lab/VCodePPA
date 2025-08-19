module MuxTree #(parameter W=4, N=8) (
    input [N-1:0][W-1:0] din,
    input [$clog2(N)-1:0] sel,
    output [W-1:0] dout
);
generate
    if (N == 1) assign dout = din[0];
    else begin
        wire [W-1:0] low = din[sel[$clog2(N)-1] ? N/2 : 0];
        assign dout = low[sel[$clog2(N)-2:0]];
    end
endgenerate
endmodule