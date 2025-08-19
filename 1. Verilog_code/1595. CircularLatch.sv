module CircularLatch #(parameter SIZE=8) (
    input clk, en, dir,
    output reg [SIZE-1:0] q
);
always @(posedge clk)
    if(en) q <= dir ? {q[SIZE-2:0], q[SIZE-1]} : {q[0], q[SIZE-1:1]};
endmodule