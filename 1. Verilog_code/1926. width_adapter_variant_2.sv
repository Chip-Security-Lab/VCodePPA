//SystemVerilog
module width_adapter #(parameter IN_DW = 32, OUT_DW = 16) (
    input  [IN_DW-1:0] data_in,
    input              sign_extend,
    output [OUT_DW-1:0] data_out
);
    wire upper_bits_nonzero;
    wire [OUT_DW-1:0] lower_bits;
    wire sign_bit;
    wire [OUT_DW-1:0] sign_fill;
    reg  [OUT_DW-1:0] data_out_reg;

    assign upper_bits_nonzero = |data_in[IN_DW-1:OUT_DW];
    assign lower_bits = data_in[OUT_DW-1:0];
    assign sign_bit = data_in[IN_DW-1];
    assign sign_fill = {OUT_DW{sign_bit}};

    always @(*) begin
        // (upper_bits_nonzero & sign_extend) == (upper_bits_nonzero & sign_extend)
        // {sign_fill, lower_bits} for OUT_DW*2 bits, but output only OUT_DW bits
        // So, only need sign extension if required, else lower_bits
        if (upper_bits_nonzero & sign_extend) begin
            data_out_reg = sign_fill | lower_bits;
        end else begin
            data_out_reg = lower_bits;
        end
    end

    assign data_out = data_out_reg;

endmodule