module mux_convert #(parameter DW=8, CH=4) (
    input [CH*DW-1:0] data_in,
    input [$clog2(CH)-1:0] sel,
    input en,
    output reg [DW-1:0] data_out
);
    always @* begin
        if(en) data_out = data_in[sel*DW +: DW];
        else data_out = 'bz;
    end
endmodule
