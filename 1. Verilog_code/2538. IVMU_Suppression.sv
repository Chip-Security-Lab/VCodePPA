module IVMU_Suppression #(parameter MASK_W=8) (
    input clk, global_mask,
    input [MASK_W-1:0] irq,
    output reg [MASK_W-1:0] valid_irq
);
always @(posedge clk) begin
    valid_irq <= global_mask ? 0 : irq;
end
endmodule
