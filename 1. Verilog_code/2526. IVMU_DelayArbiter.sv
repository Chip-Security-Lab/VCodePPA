module IVMU_DelayArbiter #(parameter DELAY=3) (
    input clk, 
    input [3:0] irq,
    output reg [1:0] grant
);
reg [DELAY-1:0] cnt;
always @(posedge clk) begin
    if (|irq) begin
        cnt <= (cnt == DELAY-1) ? 0 : cnt + 1;
        grant <= (cnt == 0) ? 
               (irq[0] ? 0 : irq[1] ? 1 : 2) : grant;
    end
end
endmodule
