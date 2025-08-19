module SyncLatch #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
always @(posedge clk or negedge rst_n)
    if(!rst_n) q <= 0;
    else if(en) q <= d;
endmodule