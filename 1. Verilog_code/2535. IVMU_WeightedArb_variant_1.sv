//SystemVerilog
module IVMU_WeightedArb_Pipelined #(parameter W1=3, W2=2, W3=1) (
    input clk,
    input rst_n, // Active low reset
    input irq1, irq2, irq3,
    output [1:0] sel
);

// State registers (Counters) - Hold the current value of the counters
// These are updated every clock cycle based on inputs and previous state
reg [7:0] cnt1, cnt2, cnt3;

// Pipeline registers for Stage 1 output - Hold the calculated next counter values
// These values are computed in Stage 1 and passed to Stage 2 for comparison
reg [7:0] cnt1_s1, cnt2_s1, cnt3_s1;

// Pipeline register for Stage 2 output - Hold the final selection result
// This is the output of the pipeline
reg [1:0] sel_s2;

// Combinational logic for Stage 1: Calculate the potential next values of the counters
// This logic takes current counter values (state) and current IRQ inputs
// This forms the first stage of the pipeline
wire [7:0] cnt1_next_calc = irq1 ? cnt1 + W1 : 0;
wire [7:0] cnt2_next_calc = irq2 ? cnt2 + W2 : 0;
wire [7:0] cnt3_next_calc = irq3 ? cnt3 + W3 : 0;

// Combinational logic for Stage 2: Determine the selection based on the calculated
// next counter values from Stage 1 (held in cnt_s1 registers)
// This forms the second stage of the pipeline
wire [1:0] sel_calc = (cnt1_s1 > cnt2_s1 && cnt1_s1 > cnt3_s1) ? 0 :
                      (cnt2_s1 > cnt3_s1) ? 1 : 2;

// Sequential logic: Update registers on positive clock edge or negative reset edge
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all state and pipeline registers to a known state
        cnt1 <= 0;
        cnt2 <= 0;
        cnt3 <= 0;
        cnt1_s1 <= 0;
        cnt2_s1 <= 0;
        cnt3_s1 <= 0;
        sel_s2 <= 0;
    end else begin
        // Update state counters with the values calculated in Stage 1
        // This forms the feedback loop for the state, used in the next cycle's Stage 1 calculation
        cnt1 <= cnt1_next_calc;
        cnt2 <= cnt2_next_calc;
        cnt3 <= cnt3_next_calc;

        // Register the calculated next counter values (output of Stage 1)
        // These values are passed to Stage 2 as inputs in the next clock cycle
        cnt1_s1 <= cnt1_next_calc;
        cnt2_s1 <= cnt2_next_calc;
        cnt3_s1 <= cnt3_next_calc;

        // Register the selection result (output of Stage 2)
        // This value becomes the module's output after this clock edge
        sel_s2 <= sel_calc;
    end
end

// Assign the final registered selection result (output of Stage 2) to the module output
assign sel = sel_s2;

endmodule