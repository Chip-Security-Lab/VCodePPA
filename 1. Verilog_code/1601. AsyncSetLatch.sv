module AsyncSetLatch #(parameter W=8) (
    input clk, set,
    input [W-1:0] d,
    output reg [W-1:0] q
);
always @(posedge clk or posedge set)
    if(set) q <= {W{1'b1}};
    else q <= d;
endmodule