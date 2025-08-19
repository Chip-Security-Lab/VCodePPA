module DelayLatch #(parameter DW=8, DEPTH=3) (
    input clk, en,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
reg [DW-1:0] delay_chain [0:DEPTH];
integer i;

always @(posedge clk) begin
    if(en) begin
        delay_chain[0] <= din;
        for(i=1; i<=DEPTH; i=i+1)
            delay_chain[i] <= delay_chain[i-1];
    end
end

assign dout = delay_chain[DEPTH];
endmodule