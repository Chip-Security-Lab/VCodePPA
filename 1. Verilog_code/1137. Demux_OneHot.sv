module Demux_OneHot #(parameter DW=16, N=4) (
    input [DW-1:0] din,
    input [N-1:0] sel,
    output [N-1:0][DW-1:0] dout
);
generate genvar i;
for(i=0; i<N; i=i+1) begin
    assign dout[i] = sel[i] ? din : {DW{1'b0}};
end
endgenerate
endmodule