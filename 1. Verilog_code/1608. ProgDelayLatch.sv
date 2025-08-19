module ProgDelayLatch #(parameter DW=8) (
    input clk,
    input [DW-1:0] din,
    input [3:0] delay,
    output reg [DW-1:0] dout
);
reg [DW-1:0] delay_line [0:15];
integer i;
always @(posedge clk) begin
    delay_line[0] <= din;
    for(i=1; i<16; i=i+1)
        delay_line[i] <= delay_line[i-1];
    dout <= delay_line[delay];
end
endmodule