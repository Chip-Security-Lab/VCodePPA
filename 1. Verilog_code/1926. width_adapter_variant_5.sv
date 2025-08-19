//SystemVerilog
module width_adapter #(parameter IN_DW=32, OUT_DW=16) (
    input  [IN_DW-1:0] data_in,
    input              sign_extend,
    output [OUT_DW-1:0] data_out
);
    wire upper_bits_nonzero;
    wire extend_enable;
    wire [OUT_DW-1:0] sign_ext_bits;
    wire [OUT_DW-1:0] lower_bits;

    assign upper_bits_nonzero = |data_in[IN_DW-1:OUT_DW];
    assign extend_enable = upper_bits_nonzero & sign_extend;
    assign sign_ext_bits = {OUT_DW{data_in[IN_DW-1]}};
    assign lower_bits = data_in[OUT_DW-1:0];
    assign data_out = ({OUT_DW{extend_enable}} & sign_ext_bits) | ({OUT_DW{~extend_enable}} & lower_bits);

endmodule