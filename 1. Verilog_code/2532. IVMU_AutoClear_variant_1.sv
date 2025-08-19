//SystemVerilog
module IVMU_AutoClear #(parameter W=8) (
    input clk, ack,
    input [W-1:0] irq,
    output reg [W-1:0] active_irq
);

always @(posedge clk) begin
    active_irq <= ack ? {W{1'b0}} : (active_irq | irq);
end

endmodule