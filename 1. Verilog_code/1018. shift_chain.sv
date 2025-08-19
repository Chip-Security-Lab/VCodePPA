module shift_chain #(parameter LEN=4, WIDTH=8) (
    input clk,
    input [WIDTH-1:0] ser_in,
    output [WIDTH-1:0] ser_out
);
reg [WIDTH-1:0] chain [0:LEN-1];
integer i;
always @(posedge clk) begin
    chain[0] <= ser_in;
    for(i=1; i<LEN; i=i+1)
        chain[i] <= chain[i-1];
end
assign ser_out = chain[LEN-1];
endmodule