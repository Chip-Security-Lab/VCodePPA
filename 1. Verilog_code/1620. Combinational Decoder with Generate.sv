module gen_decoder #(
    parameter WIDTH = 3
)(
    input [WIDTH-1:0] addr,
    input enable,
    output [2**WIDTH-1:0] dec_out
);
    wire [2**WIDTH-1:0] temp_out;
    genvar i;
    generate
        for (i = 0; i < 2**WIDTH; i = i + 1) begin: gen_loop
            assign temp_out[i] = (addr == i) ? 1'b1 : 1'b0;
        end
    endgenerate
    assign dec_out = enable ? temp_out : {(2**WIDTH){1'b0}};
endmodule