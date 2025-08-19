module TriStateLatch #(parameter BITS=8) (
    input clk, oe,
    input [BITS-1:0] d,
    output [BITS-1:0] q
);
reg [BITS-1:0] latched;
always @(posedge clk) latched <= d;
assign q = oe ? latched : {BITS{1'bz}};
endmodule