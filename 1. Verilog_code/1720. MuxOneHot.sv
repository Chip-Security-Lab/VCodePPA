module MuxOneHot #(parameter W=4, N=8) (
    input [N-1:0] hot_sel,
    input [N-1:0][W-1:0] channels,
    output [W-1:0] selected
);
assign selected = |(channels & {N{hot_sel}});
endmodule