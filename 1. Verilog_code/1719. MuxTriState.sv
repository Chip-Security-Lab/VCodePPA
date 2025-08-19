module MuxTriState #(parameter W=8, N=4) (
    inout [W-1:0] bus,
    input [W-1:0] data_in [0:N-1], // 修改数组声明
    input [N-1:0] oe
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin: gen_mux
            assign bus = oe[i] ? data_in[i] : {W{1'bz}};
        end
    endgenerate
endmodule