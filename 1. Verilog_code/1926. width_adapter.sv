module width_adapter #(parameter IN_DW=32, OUT_DW=16) (
    input [IN_DW-1:0] data_in,
    input sign_extend,
    output [OUT_DW-1:0] data_out
);
    localparam RATIO = IN_DW / OUT_DW;
    
    assign data_out = (|data_in[IN_DW-1:OUT_DW] && sign_extend) ? 
                    { {OUT_DW{data_in[IN_DW-1]}}, data_in[OUT_DW-1:0]} : 
                    data_in[OUT_DW-1:0];
endmodule
