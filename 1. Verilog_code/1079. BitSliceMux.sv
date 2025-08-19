module BitSliceMux #(parameter N=4, DW=4) (
    input [N-1:0] sel,
    input [(DW*N)-1:0] din, // 改为一维数组
    output [DW-1:0] dout
);
genvar i, j;
generate
    for(i=0; i<DW; i=i+1) begin: slice_loop
        wire [N-1:0] bit_select;
        for(j=0; j<N; j=j+1) begin: bit_loop
            assign bit_select[j] = din[(j*DW) + i] & sel[j];
        end
        assign dout[i] = |bit_select;
    end
endgenerate
endmodule