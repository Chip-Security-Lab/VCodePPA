//SystemVerilog
module IVMU_WeightedArb #(parameter W1=3, W2=2, W3=1) (
    input clk,
    input rst_n, // Synchronous reset, active low
    input irq1, irq2, irq3,
    output [1:0] sel
);

// State registers for counters (hold value from previous cycle)
// These registers are updated with the result of the single-stage calculation
reg [7:0] cnt1_state;
reg [7:0] cnt2_state;
reg [7:0] cnt3_state;

// Pipeline register storing the output of the single stage
// This register holds the final output
reg [1:0] sel_stage1;

// Assign the output to the final pipeline register
assign sel = sel_stage1;

// Single Stage Combinational Logic:
// 1. Calculate the next counter values based on current state and IRQ inputs
// 2. Calculate the selection based on the calculated next counter values
wire [7:0] cnt1_next = irq1 ? cnt1_state + W1 : 0;
wire [7:0] cnt2_next = irq2 ? cnt2_state + W2 : 0;
wire [7:0] cnt3_next = irq3 ? cnt3_state + W3 : 0;

wire [1:0] sel_comb = (cnt1_next > cnt2_next && cnt1_next > cnt3_next) ? 0 :
                      (cnt2_next > cnt3_next) ? 1 : 2;

// Clocked Logic with Synchronous Reset
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registers to a known state
        cnt1_state <= 0;
        cnt2_state <= 0;
        cnt3_state <= 0;
        sel_stage1 <= 0;
    end else begin
        // Update the state registers with the next calculated values
        cnt1_state <= cnt1_next;
        cnt2_state <= cnt2_next;
        cnt3_state <= cnt3_next;

        // Update the output pipeline register with the calculated selection
        sel_stage1 <= sel_comb;
    end
end

endmodule