module MuxLatch #(parameter DW=4, SEL=2) (
    input clk, 
    input [2**SEL-1:0][DW-1:0] din,
    input [SEL-1:0] sel,
    output reg [DW-1:0] dout
);
always @(posedge clk) 
    dout <= din[sel];
endmodule