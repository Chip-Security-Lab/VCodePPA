//SystemVerilog
// Submodule: weighted_counter
// Implements a synchronous counter that increments by a weight if irq is high, resets otherwise.
module weighted_counter #(
    parameter CNT_WIDTH = 8,
    parameter WEIGHT = 1
) (
    input clk,
    input irq,
    output reg [CNT_WIDTH-1:0] count
);

always @(posedge clk) begin
    if (irq) begin
        count <= count + WEIGHT;
    end else begin
        count <= {CNT_WIDTH{1'b0}}; // Reset to zero
    end
end

endmodule

// Top-level module: IVMU_WeightedArb
// Weighted arbiter using hierarchical counter submodules.
module IVMU_WeightedArb #(
    parameter W1 = 3,
    parameter W2 = 2,
    parameter W3 = 1,
    parameter CNT_WIDTH = 8 // Parameter for counter width
) (
    input clk,
    input irq1,
    input irq2,
    input irq3,
    output reg [1:0] sel
);

// Internal wires to connect counter outputs to arbitration logic
wire [CNT_WIDTH-1:0] cnt1_val;
wire [CNT_WIDTH-1:0] cnt2_val;
wire [CNT_WIDTH-1:0] cnt3_val;

// Instantiate weighted_counter modules for each IRQ
weighted_counter #(
    .CNT_WIDTH (CNT_WIDTH),
    .WEIGHT    (W1)
) counter1_inst (
    .clk  (clk),
    .irq  (irq1),
    .count(cnt1_val)
);

weighted_counter #(
    .CNT_WIDTH (CNT_WIDTH),
    .WEIGHT    (W2)
) counter2_inst (
    .clk  (clk),
    .irq  (irq2),
    .count(cnt2_val)
);

weighted_counter #(
    .CNT_WIDTH (CNT_WIDTH),
    .WEIGHT    (W3)
) counter3_inst (
    .clk  (clk),
    .irq  (irq3),
    .count(cnt3_val)
);

// Synchronous arbitration/selection logic based on counter values
always @(posedge clk) begin
    if (cnt1_val > cnt2_val && cnt1_val > cnt3_val) begin
        sel <= 2'b00; // Select IRQ1
    end else if (cnt2_val > cnt3_val) begin
        sel <= 2'b01; // Select IRQ2 (since IRQ1 was not highest)
    end else begin
        sel <= 2'b10; // Select IRQ3 (since IRQ1 and IRQ2 were not highest)
    end
end

endmodule