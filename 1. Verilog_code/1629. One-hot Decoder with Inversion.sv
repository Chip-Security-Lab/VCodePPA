module invert_decoder #(
    parameter INVERT_OUTPUT = 0
)(
    input [2:0] bin_addr,
    output [7:0] dec_out
);
    wire [7:0] temp_out;
    assign temp_out = (8'b00000001 << bin_addr);
    assign dec_out = INVERT_OUTPUT ? ~temp_out : temp_out;
endmodule