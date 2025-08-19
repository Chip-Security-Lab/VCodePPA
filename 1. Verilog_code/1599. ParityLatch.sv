module ParityLatch #(parameter DW=7) (
    input clk, en,
    input [DW-1:0] data,
    output reg [DW:0] q
);
always @(posedge clk)
    if(en) q <= {^data, data};
endmodule