module IVMU_DualTrigger (
    input clk, edge_mode,
    input async_irq,
    output reg sync_irq
);
reg last;
always @(posedge clk) begin
    last <= async_irq;
    sync_irq <= edge_mode ? 
               async_irq & ~last : 
               async_irq;
end
endmodule
