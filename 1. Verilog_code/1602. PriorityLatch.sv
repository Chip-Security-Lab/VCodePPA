module PriorityLatch #(parameter N=4) (
    input clk, en,
    input [N-1:0] req,
    output reg [N-1:0] grant
);
always @(posedge clk)
    if(en) grant <= req & (~req + 1);
endmodule