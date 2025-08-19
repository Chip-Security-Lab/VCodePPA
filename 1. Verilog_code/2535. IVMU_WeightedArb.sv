module IVMU_WeightedArb #(parameter W1=3, W2=2, W3=1) (
    input clk,
    input irq1, irq2, irq3,
    output reg [1:0] sel
);
reg [7:0] cnt1, cnt2, cnt3;
always @(posedge clk) begin
    cnt1 <= irq1 ? cnt1 + W1 : 0;
    cnt2 <= irq2 ? cnt2 + W2 : 0;
    cnt3 <= irq3 ? cnt3 + W3 : 0;
    sel <= (cnt1 > cnt2 && cnt1 > cnt3) ? 0 :
          (cnt2 > cnt3) ? 1 : 2;
end
endmodule
