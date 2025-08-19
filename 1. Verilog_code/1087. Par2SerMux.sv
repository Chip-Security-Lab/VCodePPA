module Par2SerMux #(parameter DW=8) (
    input clk, load,
    input [DW-1:0] par_in,
    output ser_out
);
reg [DW-1:0] shift;
always @(posedge clk)
    shift <= load ? par_in : shift >> 1;
assign ser_out = shift[0];
endmodule
