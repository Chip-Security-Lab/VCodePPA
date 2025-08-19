//SystemVerilog
module IVMU_DelayArbiter #(parameter DELAY=3) (
    input clk,
    input [3:0] irq,
    output reg [1:0] grant
);

// Internal counter register
reg [DELAY-1:0] cnt;

// Wire to indicate if any IRQ is asserted
wire any_irq = |irq;

// Counter Logic Block
// Updates the counter based on the 'any_irq' signal.
// The counter increments when any IRQ is asserted and resets when it reaches DELAY-1.
// It holds its value when no IRQ is asserted.
always @(posedge clk) begin
    if (any_irq) begin
        if (cnt == DELAY-1) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end
end

// Grant Logic Block
// Updates the grant signal based on the counter value and IRQ inputs.
// The grant is updated only when any IRQ is asserted AND the counter is 0.
// It prioritizes irq[0], then irq[1], then irq[2]. irq[3] is ignored for grant assignment.
always @(posedge clk) begin
    // Grant is assigned only when any IRQ is active AND the delay counter is at 0
    if (any_irq && cnt == 0) begin
        // Priority encoder for grant based on irq[0] to irq[2]
        if (irq[0]) begin
            grant <= 2'b00; // Grant to IRQ 0
        end else if (irq[1]) begin
            grant <= 2'b01; // Grant to IRQ 1
        end else if (irq[2]) begin
            grant <= 2'b10; // Grant to IRQ 2
        end
        // If irq[0..2] are all low but any_irq is high (meaning irq[3] is high),
        // the grant value holds its previous state, matching the original logic's behavior
        // where grant was only assigned when cnt==0 and |irq was true.
    end
    // If any_irq is low, or if any_irq is high but cnt is not 0, grant holds its value.
end

endmodule