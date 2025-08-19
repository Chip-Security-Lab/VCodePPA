module RD6 #(parameter WIDTH=8, DEPTH=4)(
  input clk, input arstn,
  input [WIDTH-1:0] shift_in,
  output [WIDTH-1:0] shift_out
);
reg [WIDTH-1:0] shreg [0:DEPTH-1];
integer j;
always @(posedge clk or negedge arstn) begin
  if (!arstn) begin
    for (j=0; j<DEPTH; j=j+1) shreg[j] <= 0;
  end else begin
    shreg[0] <= shift_in;
    for (j=1; j<DEPTH; j=j+1) shreg[j] <= shreg[j-1];
  end
end
assign shift_out = shreg[DEPTH-1];
endmodule
