module sign_extend #(parameter IN_W=8, OUT_W=16) (
    input [IN_W-1:0] data_in,
    input use_sign,
    output reg [OUT_W-1:0] data_out
);
always @(*) begin
    data_out = use_sign ? {{(OUT_W-IN_W){data_in[IN_W-1]}}, data_in} : 
                         {{(OUT_W-IN_W){1'b0}}, data_in};
end
endmodule